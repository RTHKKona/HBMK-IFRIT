## Credit to Fexty for the original code.
## This Version 1.1 (Handburger)

import ffmpeg
import argparse
import subprocess
import struct
import sys
import os
from pathlib import Path

class CapcomAdpcmHeader:
    def __init__(self, samples, datasize, loop_flag, loop_start, loop_end, coefs):
        self.samples = samples
        self.datasize = datasize
        self.loop_flag = loop_flag
        self.loop_start = loop_start
        self.loop_end = loop_end
        self.coefs = coefs
        self.channels = 1
        self.sample_rate = 48000
        self.duration = samples / self.sample_rate
    
    def to_bytes(self):
        main_header = struct.pack('<IHHIf', 2, self.channels, 256, self.datasize, self.duration)
        header_unkn = struct.pack('<HHHH', 2017, 520, 2828, 40)
        coefs = struct.pack('<HHHHHHHHHHHHHHHH', *self.coefs)
        padding = b'\0' * 40
        channel_header = struct.pack('<II?xxxIII', self.samples, self.sample_rate, self.loop_flag, self.loop_start, self.loop_end, 0)
        full_header = main_header + header_unkn + coefs + padding + channel_header
        assert(len(full_header) == 0x78)
        return full_header
    

class DspAdpcmHeader:
    def __init__(self):
        self.samples = 0
        self.sample_rate = 0
        self.channels = 0
        self.coefs = []
        self.loop_flag = False
        self.loop_start = 0
        self.loop_end = 0
    
    @staticmethod
    def _nibbles_to_samples(nibbles):
        whole_frames = nibbles // 16
        remainder = nibbles % 16
        return whole_frames * 14 + remainder - 2 if remainder > 0 else whole_frames * 14

    @staticmethod
    def from_bytes(data):
        header = DspAdpcmHeader()
        header.samples, header.sample_rate, header.loop_flag, loop_start, loop_end = struct.unpack_from('<IxxxxI?xxxII', data)
        header.loop_start = DspAdpcmHeader._nibbles_to_samples(loop_start)
        header.loop_end = DspAdpcmHeader._nibbles_to_samples(loop_end) + 1
        coefs = struct.unpack_from('<HHHHHHHHHHHHHHHH', data, 0x1C)
        header.coefs = list(coefs)
        header.channels = 1
        return header

def convert_wav_to_16bit_pcm(input_file, output_file):
    ffmpeg_path = os.path.join(os.path.dirname(__file__), "ffmpeg.exe")
    stream = ffmpeg.input(input_file)
    stream = ffmpeg.output(stream, output_file, acodec='pcm_s16le', ar=48000, ac=1)
    ffmpeg.run(stream)

def convert_wav_to_dspadpcm(input_file, output_file, loop_start = 0, loop_end = 0):
    is_looped = loop_start not in [0, None] and loop_end not in [0, None]
    loop_context = ['--loop-begin', str(loop_start), '--loop-end', str(loop_end)] if is_looped else []
    subprocess.run(['AdpcmEncoder.exe', input_file, '-o', output_file, *loop_context], check=True)

def convert_dspadpcm_to_capcom_adpcm(input_file, output_file):
    with open(input_file, 'rb') as f:
        header = DspAdpcmHeader.from_bytes(f.read(0x60))
        data = f.read()
    
    capcom_header = CapcomAdpcmHeader(header.samples, len(data), header.loop_flag, header.loop_start, header.loop_end, header.coefs)
    with open(output_file, 'wb') as f:
        f.write(capcom_header.to_bytes())
        # Pad 'data' to 16 bytes
        f.write(data + b'\0' * (16 - len(data) % 16))

def wav2adpcm(input_file, output_file, loop_start = 0, loop_end = 0):
    temp_pcm = os.path.dirname(sys.argv[0]) + "/tmp/temp.wav"
    temp_adpcm = os.path.dirname(sys.argv[0]) + "/tmp/temp.adpcm"
    os.makedirs(os.path.dirname(temp_pcm), exist_ok=True)

    convert_wav_to_16bit_pcm(input_file, temp_pcm)
    convert_wav_to_dspadpcm(temp_pcm, temp_adpcm, loop_start, loop_end)
    convert_dspadpcm_to_capcom_adpcm(temp_adpcm, output_file)

    os.remove(temp_pcm)
    os.remove(temp_adpcm)

    print(f'Converted {input_file} to Capcom ADPCM format')


def main_singlefile():
    parser = argparse.ArgumentParser(description='Convert a WAV file to DSP-ADPCM format')
    parser.add_argument('input', help='input WAV file')
    parser.add_argument('output', help='output Capcom ADPCM file')
    parser.add_argument('--loop-start', type=int, help='loop start point in samples')
    parser.add_argument('--loop-end', type=int, help='loop end point in samples')
    args = parser.parse_args()
    wav2adpcm(args.input, args.output, args.loop_start, args.loop_end)


def main_dirtree():
    parser = argparse.ArgumentParser(description='Convert a directory tree of WAV files to Capcom ADPCM format')
    parser.add_argument('input', help='input directory')
    args = parser.parse_args()

    for file in Path(args.input).rglob('*.wav'):
        output_file = file.with_suffix('.adpcm')
        wav2adpcm(file, output_file)


if __name__ == '__main__':
    main_singlefile()
