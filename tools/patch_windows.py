#!/usr/bin/env python3
"""Patch icon/version of an unsigned Godot Windows PE without rewriting code.
Requires pefile + Pillow; run tools/export_icon.gd first. Uses small mmap writes,
not pefile.PE.write(), which needs excessive memory for the 81 MiB template.
"""
from pathlib import Path
import array
import io
import mmap
import struct
import sys
import pefile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'build/windows/Grindlish.exe'
pe = pefile.PE(str(PATH), fast_load=True)
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_RESOURCE']])
assert pe.FILE_HEADER.Machine == 0x8664
assert pe.OPTIONAL_HEADER.DATA_DIRECTORY[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_SECURITY']].Size == 0, 'Do not alter a signed executable'
resources, groups = {}, []
for kind in pe.DIRECTORY_ENTRY_RESOURCE.entries:
    if kind.id in (3, 14):
        for resource in kind.directory.entries:
            for language in resource.directory.entries:
                if kind.id == 3:
                    resources[resource.id] = language.data.struct
                else:
                    groups.append(language.data.struct)
icon = Image.open(ROOT / 'build/icon.png').convert('RGBA')
changed = 0
with PATH.open('r+b') as file, mmap.mmap(file.fileno(), 0) as data:
    for group in groups:
        offset = pe.get_offset_from_rva(group.OffsetToData)
        blob = bytearray(data[offset:offset + group.Size])
        for index in range(struct.unpack_from('<H', blob, 4)[0]):
            pos = 6 + index * 14
            width, height = blob[pos] or 256, blob[pos + 1] or 256
            resource = resources[struct.unpack_from('<H', blob, pos + 12)[0]]
            buffer = io.BytesIO()
            icon.resize((width, height), Image.Resampling.LANCZOS).save(buffer, format='PNG')
            png = buffer.getvalue()
            assert len(png) <= resource.Size, 'New icon exceeds existing resource allocation'
            start = pe.get_offset_from_rva(resource.OffsetToData)
            data[start:start + resource.Size] = png + bytes(resource.Size - len(png))
            struct.pack_into('<I', data, resource.get_file_offset() + 4, len(png))
            struct.pack_into('<I', blob, pos + 8, len(png))
            changed += 1
        data[offset:offset + len(blob)] = blob
    for group in pe.FileInfo:
        for item in group:
            if item.Key == b'StringFileInfo':
                for table in item.StringTable:
                    updates = {b'CompanyName': '', b'FileDescription': 'Grindlish', b'ProductName': 'Grindlish', b'FileVersion': '0.2', b'ProductVersion': '0.2.0'}
                    for key, value in updates.items():
                        offset = table.entries_offsets[key][1]
                        capacity = table.entries_lengths[key][1]
                        assert len(value) <= capacity
                        data[offset:offset + capacity * 2] = value.encode('utf-16le').ljust(capacity * 2, b'\0')
    for version in pe.VS_FIXEDFILEINFO:
        for field, value in [('FileVersionMS', 2), ('FileVersionLS', 0), ('ProductVersionMS', 2), ('ProductVersionLS', 0)]:
            struct.pack_into('<I', data, version.get_field_absolute_offset(field), value)
    checksum_offset = pe.OPTIONAL_HEADER.get_field_absolute_offset('CheckSum')
    struct.pack_into('<I', data, checksum_offset, 0)
    checksum = 0
    for offset in range(0, len(data), 1024 * 1024):
        block = data[offset:offset + 1024 * 1024]
        if len(block) % 2:
            block += b'\0'
        words = array.array('H')
        words.frombytes(block)
        if sys.byteorder != 'little':
            words.byteswap()
        checksum += sum(words)
        checksum = (checksum & 0xffff) + (checksum >> 16)
    checksum = (checksum & 0xffff) + (checksum >> 16)
    checksum = ((checksum & 0xffff) + (checksum >> 16)) & 0xffff
    checksum += len(data)
    struct.pack_into('<I', data, checksum_offset, checksum)
    data.flush()
pe.close()
verify = pefile.PE(str(PATH), fast_load=True)
verify.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_RESOURCE']])
assert changed == 6
names = [table.entries[b'ProductName'].rstrip(b'\0') for group in verify.FileInfo for item in group if item.Key == b'StringFileInfo' for table in item.StringTable]
assert names == [b'Grindlish']
# Independent pefile implementation checks the streamed checksum once.
assert verify.OPTIONAL_HEADER.CheckSum == verify.generate_checksum()
verify.close()
print('PE validated: x86_64; six Grindlish icons; product Grindlish; version 0.2.0.0.', flush=True)
print('Unsigned. Original Godot copyright preserved. Native Windows execution NOT tested.', flush=True)
