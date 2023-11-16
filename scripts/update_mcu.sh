sudo service klipper stop

cd ~/klipper
git stash -a
git pull
git stash pop

# cp -f ~/print_data/config/scripts/{config.octopus,config.sb2040,config.rpi} ~/klipper/

make clean KCONFIG_CONFIG=config.octopus
make menuconfig KCONFIG_CONFIG=config.octopus
make KCONFIG_CONFIG=config.octopus
mv ~/klipper/out/klipper.bin ~/firmware/octopus_1.1_klipper.bin
read -p "Octopus firmware built, please check above for any errors. Press [Enter] to continue building firmware, or [Ctrl+C] to abort"

make clean KCONFIG_CONFIG=config.sb2040
make menuconfig KCONFIG_CONFIG=config.sb2040
make KCONFIG_CONFIG=config.sb2040
mv ~/klipper/out/klipper.bin ~/firmware/sb2040_1.0_klipper.bin
read -p "SB2040 firmware built, please check above for any errors. Press [Enter] to continue building firmware, or [Ctrl+C] to abort"

make clean KCONFIG_CONFIG=config.rpi
make menuconfig KCONFIG_CONFIG=config.rpi
make KCONFIG_CONFIG=config.rpi
read -p "RPi firmware built, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

cd ~/CanBoot/scripts
python3 flash_can.py -i can0 -u 9d488cc48530 -f ~/firmware/sb2040_1.0_klipper.bin
read -p "SB2040 firmware flashed, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

python3 flash_can.py -i can0 -u dd8d9d6ff9fd -f ~/firmware/octopus_1.1_klipper.bin
read -p "We intentionally caused an error on the Octopus to boot into the bootloader. Please ignore and Press [Enter] to continue flashing, or [Ctrl+C] to abort"
python3 flash_can.py -d /dev/serial/by-id/usb-CanBoot_stm32f446xx_4A0021000651303431333234-if00 -f ~/firmware/octopus_1.1_klipper.bin
read -p "Octopus firmware flashed, please check above for any errors. Press [Enter] to continue flashing, or [Ctrl+C] to abort"

cd ~/klipper
make flash KCONFIG_CONFIG=config.rpi
read -p "RPi firmware flashed, please check above for any errors. Press [Enter] to finish up, or [Ctrl+C] to abort"

# cp -f ~/klipper/{config.octopus,config.sb2040,config.rpi} ~/print_data/config/scripts/

sudo service klipper start
