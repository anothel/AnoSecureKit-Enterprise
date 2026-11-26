// SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
#include <anosecurekit/aead.hpp>
#include <anosecurekit/error.hpp>
#include <anosecurekit/file.hpp>
#include <anosecurekit/hash.hpp>
#include <anosecurekit/hex.hpp>
#include <anosecurekit/packet_stream.hpp>
#include <anosecurekit/random.hpp>
#include <anosecurekit/version.hpp>
#include <anosecurekit_enterprise/enterprise.hpp>
#include <anosecurekit_enterprise/provider_runtime.hpp>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstddef>
#include <filesystem>
#include <fstream>
#include <future>
#include <iostream>
#include <iterator>
#include <optional>
#include <set>
#include <span>
#include <sstream>
#include <stdexcept>
#include <streambuf>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace
{
namespace fs = std::filesystem;
using anosecurekit::bytes;
using anosecurekit::error_code;
using anosecurekit::key256;

constexpr key256 key{};
constexpr key256 wrong_key{std::byte{1}};
constexpr std::string_view sentinel = "preexisting consumer output";

std::span<const std::byte> as_bytes(std::string_view text)
{
    return std::as_bytes(std::span(text.data(), text.size()));
}

void require(bool condition, std::string_view message)
{
    if (!condition)
    {
        throw std::runtime_error(std::string(message));
    }
}

void expect_error(error_code expected, std::string_view operation, auto&& call)
{
    try
    {
        call();
    }
    catch (const anosecurekit::error& failure)
    {
        require(failure.code() == expected, std::string(operation) + ": unexpected error code");
        return;
    }
    throw std::runtime_error(std::string(operation) + ": unexpectedly succeeded");
}

struct packet_quarantine
{
    bytes pending;

    void discard()
    {
        std::ranges::fill(pending, std::byte{});
        pending.clear();
    }

    ~packet_quarantine() { discard(); }
};

void check_packets()
{
    const auto message = as_bytes("synthetic SKT1 plaintext");
    const auto aad = as_bytes("installed SKT1 consumer");
    const auto packet = anosecurekit::encrypt(message, key, aad);
    require(std::ranges::equal(anosecurekit::decrypt(packet, key, aad), message),
            "SKT1 one-shot round trip");
    expect_error(error_code::authentication_failed, "SKT1 wrong key",
                 [&] { (void)anosecurekit::decrypt(packet, wrong_key, aad); });
    expect_error(error_code::authentication_failed, "SKT1 wrong AAD",
                 [&] { (void)anosecurekit::decrypt(packet, key, as_bytes("other AAD")); });

    anosecurekit::packet_encryptor encryptor(key, aad);
    auto encoded = encryptor.begin();
    require(encoded.size() >= 4 && std::ranges::equal(std::span(encoded).first<4>(), as_bytes("SKT1")),
            "SKT1 prefix");
    const auto prefix = encoded;
    for (const auto chunk : {message.first(5), message.subspan(5)})
    {
        const auto ciphertext = encryptor.update(chunk);
        encoded.insert(encoded.end(), ciphertext.begin(), ciphertext.end());
    }
    const auto tag = encryptor.finalize();
    require(tag.size() == 16, "SKT1 tag size");
    const auto ciphertext = std::span<const std::byte>(encoded).subspan(prefix.size());
    require(ciphertext.size() == message.size(), "SKT1 ciphertext size");
    auto complete = encoded;
    complete.insert(complete.end(), tag.begin(), tag.end());
    require(std::ranges::equal(anosecurekit::decrypt(complete, key, aad), message),
            "SKT1 streaming seal and one-shot open");

    auto bad_tag = tag;
    bad_tag.back() ^= std::byte{1};
    auto damaged = complete;
    damaged.back() ^= std::byte{1};
    expect_error(error_code::authentication_failed, "SKT1 one-shot corrupt tag",
                 [&] { (void)anosecurekit::decrypt(damaged, key, aad); });
    const auto check_stream = [&](const key256& attempt, std::span<const std::byte> candidate,
                                  std::optional<error_code> expected, bool abort = false) {
        anosecurekit::packet_decryptor decryptor(attempt, aad);
        decryptor.begin(prefix);
        packet_quarantine first{decryptor.update(ciphertext.first(5))};
        packet_quarantine rest{decryptor.update(ciphertext.subspan(5))};
        require(first.pending.size() == 5 && rest.pending.size() == message.size() - 5,
                "SKT1 update yielded pre-authentication plaintext");
        const auto original = as_bytes(sentinel);
        bytes published(original.begin(), original.end());
        const auto finalize_and_commit = [&] {
            const auto trailing = decryptor.finalize(candidate);
            published.assign(first.pending.begin(), first.pending.end());
            published.insert(published.end(), rest.pending.begin(), rest.pending.end());
            published.insert(published.end(), trailing.begin(), trailing.end());
        };
        if (expected)
        {
            expect_error(*expected, "SKT1 stream authentication or framing rejection", finalize_and_commit);
        }
        else if (!abort)
        {
            finalize_and_commit();
            require(std::ranges::equal(published, message), "SKT1 commit after authentication");
            return;
        }

        first.discard();
        rest.discard();
        require(first.pending.empty() && rest.pending.empty() && std::ranges::equal(published, original),
                "SKT1 discard preserved published output");
    };
    check_stream(key, tag, std::nullopt);
    check_stream(wrong_key, tag, error_code::authentication_failed);
    check_stream(key, bad_tag, error_code::authentication_failed);
    check_stream(key, std::span<const std::byte>(tag).first(tag.size() - 1), error_code::invalid_packet);
    check_stream(key, {}, error_code::invalid_packet);
    check_stream(key, {}, std::nullopt, true);
}

struct scratch_directory
{
    const fs::path path = fs::temp_directory_path()
        / ("anosecurekit-installed-" + anosecurekit::hex_encode(anosecurekit::random_bytes(16)));

    scratch_directory() { require(fs::create_directory(path), "create consumer scratch directory"); }
    ~scratch_directory()
    {
        std::error_code ignored;
        fs::remove_all(path, ignored);
    }
};

void write_file(const fs::path& path, std::string_view data)
{
    std::ofstream output(path, std::ios::binary);
    output.write(data.data(), static_cast<std::streamsize>(data.size()));
    output.close();
    require(output.good(), "write synthetic test file");
}

std::string read_file(const fs::path& path)
{
    std::ifstream input(path, std::ios::binary);
    require(input.is_open(), "read synthetic test file");
    return {std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()};
}

std::set<fs::path> entries(const fs::path& directory)
{
    std::set<fs::path> paths;
    for (const auto& entry : fs::directory_iterator(directory))
    {
        paths.insert(entry.path().filename());
    }
    return paths;
}

class stream_quarantine : public std::streambuf
{
public:
    explicit stream_quarantine(std::size_t capacity) : storage_(capacity) { discard(); }
    ~stream_quarantine() override { discard(); }

    std::string_view pending() const { return {pbase(), static_cast<std::size_t>(pptr() - pbase())}; }

    void discard()
    {
        std::ranges::fill(storage_, '\0');
        setp(storage_.data(), storage_.data() + storage_.size());
    }

private:
    std::vector<char> storage_;
};

template <typename Credential>
void check_files(std::string_view format, const Credential& credential, const Credential& incorrect,
                 auto seal, auto open)
{
    const auto check = [format](bool condition, std::string_view message) {
        require(condition, std::string(format) + ": " + std::string(message));
    };
    const scratch_directory scratch;
    const auto source = scratch.path / "source";
    const auto sealed = scratch.path / "sealed";
    const auto opened = scratch.path / "opened";
    const auto failed = scratch.path / "failed";
    const auto damaged = scratch.path / "damaged";
    const auto aad = as_bytes("installed file consumer");
    // Version 1 uses 1 MiB records. Include a short second record to force late failure.
    constexpr std::size_t first_record_size = 1024 * 1024;
    const auto message = std::string(first_record_size, 'x') + "\nlast synthetic record";
    write_file(source, message);
    seal(source, sealed, credential, aad);
    auto ciphertext = read_file(sealed);
    check(ciphertext.starts_with(format), "sealed file format");
    open(sealed, opened, credential, aad);
    check(read_file(opened) == message, "authenticated path round trip");
    check(entries(scratch.path) == std::set<fs::path>{"source", "sealed", "opened"},
          "successful path operations cleaned up temporary files");

    stream_quarantine quarantine(message.size());
    std::ostream pending(&quarantine);
    std::string published(sentinel);
    const auto open_and_commit = [&](std::istream& input, const Credential& attempt) {
        open(input, pending, attempt, aad);
        published.assign(quarantine.pending());
    };
    {
        std::istringstream original(message);
        std::ostringstream sealed_stream;
        seal(original, sealed_stream, credential, aad);
        check(sealed_stream.view().starts_with(format), "sealed stream format");
        std::istringstream input(std::move(sealed_stream).str());
        open_and_commit(input, credential);
        check(published == message, "stream output committed after successful return");
        quarantine.discard();
    }
    published = sentinel;
    const auto check_failure = [&](error_code expected, const Credential& attempt,
                                   const fs::path& input_path, std::size_t staged_size) {
        const auto before = entries(scratch.path);
        expect_error(expected, std::string(format) + " path open", [&] {
            open(input_path, failed, attempt, aad);
        });
        check(!fs::exists(failed) && entries(scratch.path) == before,
              "path failure left no output or temporary file");
        std::ifstream input(input_path, std::ios::binary);
        expect_error(expected, std::string(format) + " stream open", [&] {
            open_and_commit(input, attempt);
        });
        check(quarantine.pending().size() == staged_size && published == sentinel,
              "stream failure confined partial output to quarantine");
        quarantine.discard();
        check(quarantine.pending().empty() && published == sentinel, "caller discarded staged output");
    };
    check_failure(error_code::authentication_failed, incorrect, sealed, 0);
    ciphertext.back() ^= 1;
    write_file(damaged, ciphertext);
    check_failure(error_code::authentication_failed, credential, damaged, first_record_size);
    ciphertext.pop_back();
    write_file(damaged, ciphertext);
    check_failure(error_code::invalid_packet, credential, damaged, first_record_size);

    write_file(opened, sentinel);
    const auto before = entries(scratch.path);
    expect_error(error_code::invalid_input, std::string(format) + " existing output", [&] {
        open(sealed, opened, credential, aad);
    });
    expect_error(error_code::invalid_input, std::string(format) + " damaged input with existing output", [&] {
        open(damaged, opened, credential, aad);
    });
    expect_error(error_code::invalid_input, std::string(format) + " seal with existing output", [&] {
        seal(source, opened, credential, aad);
    });
    check(read_file(opened) == sentinel && entries(scratch.path) == before,
          "path open preserved preexisting output");
}

void check_worker_lifecycle()
{
    namespace enterprise = anosecurekit_enterprise;
    const auto message = as_bytes("synthetic worker packet");
    const auto packet = anosecurekit::encrypt(message, key);
    const std::span<const std::byte> encoded(packet);
    constexpr std::size_t tag_size = 16;
    require(encoded.size() > message.size() + tag_size, "worker SKT1 packet size");
    const auto prefix_size = encoded.size() - message.size() - tag_size;

    std::promise<void> updated;
    auto update_done = updated.get_future();
    std::promise<void> finish;
    auto finish_allowed = finish.get_future();

    // Admission is owned by this test controller. The single accepted worker
    // owns its stream context and pending bytes for the entire invocation.
    bool accepting = true;
    const auto admit = [&](auto&& operation) -> std::future<void> {
        if (!accepting)
        {
            return {};
        }
        return std::async(std::launch::async, std::forward<decltype(operation)>(operation));
    };
    auto worker = admit([&, signal = std::move(updated)]() mutable {
        auto checkpoint = std::move(signal);
        anosecurekit::packet_decryptor decryptor(key);
        decryptor.begin(encoded.first(prefix_size));
        packet_quarantine staged{decryptor.update(encoded.subspan(prefix_size, message.size()))};
        checkpoint.set_value();
        finish_allowed.wait();
        const auto trailing = decryptor.finalize(encoded.last(tag_size));
        require(trailing.empty() && std::ranges::equal(staged.pending, message),
                "worker authenticated its staged plaintext");
    });
    update_done.get();
    accepting = false;
    const auto rejected = admit([] {});
    const bool in_flight = worker.wait_for(std::chrono::seconds(0)) == std::future_status::timeout;
    finish.set_value();
    worker.get();
    require(!rejected.valid() && in_flight, "stop admission before draining the live stream");

    // OpenSSL exposes a compatibility lifecycle, so this checks caller ordering
    // and fresh contexts, with no assertion about SDK shutdown enforcement.
    enterprise::shutdown_backend();
    require(enterprise::initialize_backend() == enterprise::backend_runtime_status::ready,
            "OpenSSL profile reinitialize");
    {
        anosecurekit::packet_decryptor fresh(key);
        fresh.begin(encoded.first(prefix_size));
        packet_quarantine staged{fresh.update(encoded.subspan(prefix_size, message.size()))};
        require(fresh.finalize(encoded.last(tag_size)).empty()
                    && std::ranges::equal(staged.pending, message),
                "fresh SKT1 stream after reinitialize");
    }
    enterprise::shutdown_backend();
}

} // namespace

int main()
{
    if (anosecurekit::version() != std::string_view{"0.4.0"})
    {
        return 1;
    }
    if (anosecurekit_enterprise::enterprise_version() != std::string_view{"0.1.0"})
    {
        return 2;
    }
    if (anosecurekit_enterprise::backend_profile_name() != std::string_view{"openssl"})
    {
        return 3;
    }
    if (anosecurekit_enterprise::initialize_backend()
        != anosecurekit_enterprise::backend_runtime_status::ready)
    {
        return 4;
    }
    if (!anosecurekit_enterprise::backend_profile_ready())
    {
        return 5;
    }

    constexpr std::array<std::byte, 3> input{std::byte{'a'}, std::byte{'b'}, std::byte{'c'}};
    const auto digest = anosecurekit::sha256(input);
    if (digest.size() != 32)
    {
        return 6;
    }

    try
    {
        check_packets();
        std::cout << "SKT1 one-shot, streaming, authentication and quarantine passed\n";
        check_files("SKF1", key, wrong_key,
                    [](auto& input, auto& output, const auto& credential, auto aad) {
                        anosecurekit::seal_file(input, output, credential, aad);
                    },
                    [](auto& input, auto& output, const auto& credential, auto aad) {
                        anosecurekit::open_file(input, output, credential, aad);
                    });
        std::cout << "SKF1 path and stream acceptance passed\n";
        check_files("SKP1", as_bytes("synthetic test password"), as_bytes("incorrect test password"),
                    [](auto& input, auto& output, auto credential, auto aad) {
                        anosecurekit::seal_file_with_password(input, output, credential, aad);
                    },
                    [](auto& input, auto& output, auto credential, auto aad) {
                        anosecurekit::open_file_with_password(input, output, credential, aad);
                    });
        std::cout << "SKP1 path and stream acceptance passed\n";
        check_worker_lifecycle();
        std::cout << "Test-owned SKT1 worker stop, drain, shutdown and restart passed\n";
    }
    catch (const std::exception& failure)
    {
        anosecurekit_enterprise::shutdown_backend();
        std::cerr << "Installed consumer acceptance failed: " << failure.what() << '\n';
        return 7;
    }
    return 0;
}
