```bash
cd /home/pi
rm -rf treed/.staging
mkdir -p treed/.staging
git clone --depth 1 https://github.com/Yawllen/treed-mainshellOS.git treed/.staging/treed-mainshellOS
cd treed/.staging/treed-mainshellOS/loader
chmod +x loader.sh
sudo ./loader.sh

```
