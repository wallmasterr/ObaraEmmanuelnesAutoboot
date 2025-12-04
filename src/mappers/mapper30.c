#include "mapper.h"

static uint8_t read_PRG(Mapper*, uint16_t);
static void write_PRG(Mapper*, uint16_t, uint8_t);
static uint8_t read_CHR(Mapper*, uint16_t);
static void write_CHR(Mapper*, uint16_t, uint8_t);

void load_Mapper30(Mapper* mapper){
    mapper->read_PRG = read_PRG;
    mapper->write_PRG = write_PRG;
    mapper->read_CHR = read_CHR;
    mapper->write_CHR = write_CHR;
    // last bank offset
    mapper->clamp = (mapper->PRG_banks - 1) * 0x4000;
    mapper->PRG_ptr = mapper->PRG_ROM;
    // Start with vertical mirroring (as required by the game)
    set_mirroring(mapper, VERTICAL);
}


static uint8_t read_PRG(Mapper* mapper, uint16_t address){
    if(address < 0xC000)
        return *(mapper->PRG_ptr + (address - 0x8000));
    else
        return mapper->PRG_ROM[mapper->clamp + (address - 0xC000)];
}


static void write_PRG(Mapper* mapper, uint16_t address, uint8_t value){
    if(address >= 0x8000) {
        // Lower 5 bits select PRG bank (0-31, supports up to 512KB)
        uint8_t bank = value & 0x1F;
        uint16_t max_banks = mapper->PRG_banks;
        if(max_banks > 0) {
            bank = bank % max_banks;
        }
        mapper->PRG_ptr = mapper->PRG_ROM + bank * 0x4000;
        
        // Bit 6 controls mirroring (0 = vertical, 1 = horizontal)
        // Always use vertical mirroring for this game
        // if(value & 0x40) {
        //     set_mirroring(mapper, HORIZONTAL);
        // } else {
        //     set_mirroring(mapper, VERTICAL);
        // }
    }
}

static uint8_t read_CHR(Mapper* mapper, uint16_t address){
    if(address < 0x2000) {
        if(mapper->CHR_banks == 0) {
            // CHR RAM
            if(address < mapper->CHR_RAM_size) {
                return mapper->CHR_ROM[address];
            }
            return 0;
        }
        // CHR ROM (up to 256KB, 32 banks of 8KB)
        return mapper->CHR_ROM[address % (mapper->CHR_banks * 0x2000)];
    }
    return 0;
}

static void write_CHR(Mapper* mapper, uint16_t address, uint8_t value){
    if(mapper->CHR_banks == 0 && address < 0x2000) {
        // CHR RAM
        if(address < mapper->CHR_RAM_size) {
            mapper->CHR_ROM[address] = value;
        }
    }
}

