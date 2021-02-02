#!/usr/bin/env dash

if ! command -v ttfautohint 1>/dev/null; then
   read -rp "I need to install \`ttfautohint\`, continue? [yN] " yn
   case $yn in
      [Yy]*) brew install ttfautohint;;
          *) exit;;
   esac
   printf \\n
fi

if ! command -v fontforge 1>/dev/null; then
   read -rp "I need to install \`fontforge\`, continue? [yN] " yn
   case $yn in
      [Yy]*) brew install fontforge;;
          *) exit;;
   esac
   printf \\n
fi

if [ -d "nerd-fonts" ]; then
   (
      printf %s\\n "Updating nerd-fonts ..."
      cd "nerd-fonts" || exit 1
      git pull --depth 1
   )
else
   read -rp "I need to download nerd-fonts (~6GB), continue? [yN] " yn
   case $yn in
      [Yy]*) git clone --depth 1 "https://github.com/ryanoasis/nerd-fonts";;
          *) exit;;
   esac
fi
printf \\n

if [ -d "Iosevka" ]; then
   printf %s\\n "Updating Iosevka ..."
   cd "Iosevka" || exit 1
   git pull --depth 1
else
   printf %s\\n "Downloading Iosevka ..."
   git clone --depth 1 "https://github.com/be5invis/Iosevka"
   cd "Iosevka" || exit 1
fi
printf \\n

cp -i "../private-build-plans.toml" "./"

npm install || exit 1


if [ -d "dist/iosevka-ec" ]; then
   printf %s\\n "It looks like dist/iosevka-ec already exists would you like to:"
   printf %s\\n " - [r] Remove it and rebuild from scratch,"
   printf %s\\n " - [p] Re-patch the font with nerd-fonts patcher,"
   printf %s\\n " - [q] Abort entirely and exit?"
   read -rp "[rpQ] " resp
   case $resp in
      [Rr]*)
         rm -rf dist/iosevka-ec
         npm run build -- contents::iosevka-ec || exit 1
         ;;
      [Pp]*) ;;
      *) exit 2;;
   esac
else
   printf %s\\n "Building Iosevka ..."
   npm run build -- contents::iosevka-ec || exit 1
fi
printf \\n

printf %s\\n "Patching built Iosevka ..."
for FILE in ./dist/iosevka-ec/ttf/*.ttf; do
   fontforge -script ../nerd-fonts/font-patcher \
      --adjust-line-height --windows --complete --careful --progressbars \
      --outputdir "../" "$FILE"
done

cd "../" || exit 1

for FILE in ./*" Nerd Font Complete Windows Compatible.ttf"; do
   mv -- "$FILE" "${FILE%% Nerd Font Complete Windows Compatible.ttf}.ttf"
done
