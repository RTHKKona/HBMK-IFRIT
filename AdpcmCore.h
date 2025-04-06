#pragma once

#include <stdint.h>

typedef struct
{
    // start context
    int16_t coef[16];
    uint16_t gain;
    uint16_t pred_scale;
    int16_t yn1;
    int16_t yn2;

    // loop context
    uint16_t loop_pred_scale;
    int16_t loop_yn1;
    int16_t loop_yn2;

} ADPCMINFO;

/*---------------------------------------------------------------------------*
    exported functions pointers
 *---------------------------------------------------------------------------*/
uint32_t getBytesForAdpcmBuffer      (uint32_t samples);
uint32_t getBytesForAdpcmSamples     (uint32_t samples);
uint32_t getBytesForPcmBuffer        (uint32_t samples);
uint32_t getBytesForPcmSamples       (uint32_t samples);
uint32_t getNibbleAddress            (uint32_t samples);
uint32_t getNibblesForNSamples       (uint32_t samples);
uint32_t getSampleForAdpcmNibble     (uint32_t nibble);
uint32_t getBytesForAdpcmInfo        (void);

void encode
(
    int16_t     *src,      // location of source samples (16bit PCM signed little endian)
    uint8_t     *dst,      // location of destination buffer
    ADPCMINFO   *cxt,      // location of adpcm info
    uint32_t    samples    // number of samples to encode
);

void decode
(
    uint8_t     *src,      // location of encoded source samples
    int16_t     *dst,      // location of destination buffer (16 bits / sample)
    ADPCMINFO   *cxt,      // location of adpcm info
    uint32_t    samples    // number of samples to decode
);

void getLoopContext
(
    uint8_t     *src,      // location of ADPCM buffer in RAM
    ADPCMINFO   *cxt,      // location of adpcminfo
    uint32_t    samples    // samples to desired context
);

void decodeEx
(
    u8          *src,   // location of encoded source samples
    s16         *dst,   // location of destination buffer (16 bits / sample)
    ADPCMINFO   *cxt,   // location of adpcm info
    u32         samples,// number of samples to decode
    ADPCMINFO   *loopCxt,
    u32         loopStart
);

typedef uint32_t (*dspToolFnType1)(uint32_t);
typedef uint32_t (*dspToolFnType2)(void);
typedef void (*dspToolFnType3)(int16_t*, uint8_t*, ADPCMINFO*, uint32_t);
typedef void (*dspToolFnType4)(uint8_t*, int16_t*, ADPCMINFO*, uint32_t);
typedef void (*dspToolFnType5)(uint8_t*, ADPCMINFO*, uint32_t);
