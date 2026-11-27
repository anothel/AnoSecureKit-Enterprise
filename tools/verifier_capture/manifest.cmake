# SPDX-License-Identifier: LicenseRef-AnoSecureKit-Enterprise-Proprietary
cmake_minimum_required(VERSION 3.20)
file(SHA256 "${CAPTURE}" _digest)
file(WRITE "${RECEIPT}" "${_digest}")
