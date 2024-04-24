set -ex

git clone https://github.com/ip7z/7zip 7z

# icons
cp -f icons/FM/*.bmp 7z/CPP/7zip/UI/FileManager
cp -f icons/Archive/*.ico 7z/CPP/7zip/Archive/Icons

version=$(grep '^#define MY_VERSION_NUMBERS' 7z/C/7zVersion.h | cut -d' ' -f3 | sed 's/\s\|"//g')
echo "version=${version}" >> $GITHUB_ENV

./BuildBin.vs2022.cmd

while read -r f; do
	arch=${f%/*}
	arch=${arch##*/}
	install -Dvt ./${arch} "$f"
done < <(find 7z -name \*.sfx -o -name \*.exe -o -name \*.dll)

wget -nv https://7-zip.org/a/7z${version//.}-x64.exe
x64/7z.exe x 7z${version//.}-x64.exe

for arch in x86 x64 arm arm64; do
	(cd ${arch}
	[[ -z $(find ../7z -name \*.txt) ]] || find ../7z -name \*.txt | xargs install -vt .
	[ ! -f src-history.txt ] || mv {src-,}history.txt
	cp -r ../Lang .
	cp -r ../7-zip.chm . || true
	[[ ${arch} != x64 ]] || install -v ../x86/7-zip.dll 7-zip32.dll
	../x64/7zr.exe a ../7zip-${version}-${arch}.7z .)
done
