# Source of fields:
# https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/default_files/default_config.nu
# https://github.com/nushell/nushell/blob/main/crates/nu-utils/src/default_files/doc_config.nu
let color_datetime = {
    |dt|
    let dur = (date now) - $dt
    if ($dur > 1day) { return 'yellow' }
    if ($dur > 1hr) { return 'yellow_bold' }
    { fg: 'y', attr: 'bu' }
}
let color_filesize = {
  |fs|
  if ($fs == 0b) { return 'dimmed' }
  if ($fs < 1mb) { return 'blue' }
  'blue_bold'
}

$env.config.color_config = {
  # Primitive Values
  binary: 'magenta'
  block: 'cyan'
  bool: 'magenta'
  cell-path: 'cyan'
  closure: 'cyan_bold'
  datetime: $color_datetime
  duration: 'magenta'
  filesize: $color_filesize
  float: 'magenta'
  glob: 'green_bold'
  int: 'magenta'
  list: 'cyan'
  nothing: 'magenta'
  range: 'magenta'
  record: 'cyan'
  search_result: 'yellow_bold'
  separator: 'dimmed'
  string: 'green'

  # shape values (syntax coloring). General idea:
  # - Green is for string-like (string, glob). Bold for special strings.
  # - Red is only for errors (i.e. garbage).
  # - Magenta is for const-like (integer, bool, range, etc.).
  # - Blue is for internal commands/words.
  # - Cyan is for punctuation elements (brackets around list/table/record, etc.).
  # - Yellow is for common+important (variables, flags, paths, datetime).
  # - Default foreground is for external commands.
  # - Bold is to draw attention to special values within a category.
  shape_binary: 'magenta'
  shape_block: 'cyan'
  shape_bool: 'magenta'
  shape_closure: 'cyan_bold'
  shape_custom: 'default'
  shape_datetime: 'yellow'
  shape_directory: 'yellow'
  shape_external: { attr: 'u' }
  shape_externalarg: 'default'
  shape_external_resolved: 'default_bold'
  shape_filepath: 'yellow'
  shape_flag: 'yellow'
  shape_float: 'magenta'
  shape_garbage: { fg: 'red', attr: 'bu' },
  shape_glob_interpolation: 'green_bold'
  shape_globpattern: 'green_bold'
  shape_int: 'magenta'
  shape_internalcall: 'blue'
  shape_keyword: 'blue'
  shape_list: 'cyan'
  shape_literal: 'blue'
  shape_match_pattern: 'green_bold'
  shape_matching_brackets: { attr: u }
  shape_nothing: 'magenta'
  shape_operator: 'cyan'
  shape_pipe: 'yellow_bold'
  shape_range: 'magenta'
  shape_raw_string: 'green_bold'
  shape_record: 'cyan'
  shape_redirection: 'yellow_bold'
  shape_signature: 'cyan'
  shape_string: 'green'
  shape_string_interpolation: 'green_bold'
  shape_table: 'cyan'
  shape_vardecl: 'yellow'
  shape_variable: 'yellow'

  # Special
  leading_trailing_space_bg: 'bg_red',
  header: 'default_bold',
  empty: 'blue',
  row_index: 'dimmed',
  hints: { fg: 'dimmed', attr: 'u' },
}

$env.config.highlight_resolved_externals = true

$env.config.explore = {
  status_bar_background: { fg: 'black', bg: 'white' },
  command_bar_text: 'white',
  highlight: { fg: 'black', bg: 'yellow' },
  status: {
      error: { fg: 'red', attr: 'u' },
      warn: { fg: 'yellow', attr: 'u' }
      info: { fg: 'cyan', attr: 'u' }
  },
  selected_cell: { attr: 'r' },
}

# Colors for `ls` and similar. Entries are generated with the help of:
# - `dircolors --print-database`.
# - `vivid generate`
#
# Colors cheat sheet:
#
# Color          Fg  Bg
# ---------------------
# Black          30  40
# Red            31  41
# Green          32  42
# Yellow         33  43
# Blue           34  44
# Magenta        35  45
# Cyan           36  46
# White          37  47
# Bright Black   90 100
# Bright Red     91 101
# Bright Green   92 102
# Bright Yellow  93 103
# Bright Blue    94 104
# Bright Magenta 95 105
# Bright Cyan    96 106
# Bright White   97 107
#
# Effects:
# Default:    0
# Bold:       1
# Underlined: 4
# Reverse:    7
#
# Setting to "00" seems to disable getting particular information, which might
# be better for performance.
$env.config.completions.use_ls_colors = true
$env.config.ls.use_ls_colors = true

let ls_colors = [
  # General
  'fi=97'   # Regular file
  'rs=0'    # Reset to "normal" color
  'di=96'   # Directory
  'ln=4;97' # Symbolic link
  'mh=00'   # Regular file with more than one link
  'pi=4'    # Pipe
  'so=4'    # Socket
  'do=4'    # Door
  'bd=4'    # Block device driver
  'cd=4'    # Character device driver
  'or=91'   # "Orphan": symlink to nonexistent file or non-stat'able file
  'mi=00'   # Files which orphan's point to
  'su=00'   # Regular file that is setuid (u+s)
  'sg=00'   # Regular file that is setgid (g+s)
  'ca=00'   # Regular file with capability (very expensive to lookup)
  'tw=00'   # Dir that is sticky and other-writable (+t,o+w)
  'ow=00'   # Dir that is other-writable (o+w) and not sticky
  'st=00'   # Dir with the sticky bit set (+t) and not other-writable
  'ex=1;97' # Regular files with execute permission

  # Special text files (yellow)
  ## General
  '*CHANGELOG.md=93'
  '*CHANGELOG.txt=93'
  '*CHANGELOG=93'
  '*CODE_OF_CONDUCT.md=93'
  '*CODE_OF_CONDUCT.txt=93'
  '*CODE_OF_CONDUCT=93'
  '*CONTRIBUTING.md=93'
  '*CONTRIBUTING.txt=93'
  '*CONTRIBUTING=93'
  '*CONTRIBUTORS.md=93'
  '*CONTRIBUTORS.txt=93'
  '*CONTRIBUTORS=93'
  '*COPYING=93'
  '*COPYRIGHT=93'
  '*Dockerfile=93'
  '*FAQ=93'
  '*INSTALL.md=93'
  '*INSTALL.txt=93'
  '*INSTALL=93'
  '*LEGACY=93'
  '*LICENCE=93'
  '*LICENSE-APACHE=93'
  '*LICENSE-MIT=93'
  '*LICENSE=93'
  '*NOTICE=93'
  '*README.md=93'
  '*README.txt=93'
  '*README=93'
  '*TODO.md=93'
  '*TODO.txt=93'
  '*TODO=93'
  '*VERSION=93'
  '*passwd=93'
  '*shadow=93'

  ## Version control system
  '*.fdignore=93'
  '*.gitattributes=93'
  '*.gitconfig=93'
  '*.gitignore=93'
  '*.gitmodules=93'
  '*.hgrc=93'
  '*.ignore=93'
  '*.mailmap=93'
  '*.rgignore=93'
  '*.tfignore=93'
  '*CODEOWNERS=93'
  '*hgrc=93'

  ## Build
  '*.cmake.in=93'
  '*.cmake=93'
  '*.make=93'
  '*.mk=93'
  '*CMakeLists.txt=93'
  '*Makefile.am=93'
  '*Makefile=93'
  '*SConscript=93'
  '*SConstruct=93'
  '*configure.ac=93'
  '*configure=93'
  '*requirements.txt=93'

  ## Packaging
  '*.gemspec=93'
  '*Cargo.toml=93'
  '*MANIFEST.in=93'
  '*go.mod=93'
  '*pyproject.toml=93'
  '*setup.py=93'
  '*v.mod=93'

  # Media (green)
  ## Image
  '*.3fr=92'
  '*.ai=92'
  '*.ari=92'
  '*.arw=92'
  '*.ase=92'
  '*.aseprite=92'
  '*.avif=92'
  '*.bay=92'
  '*.bmp=92'
  '*.braw=92'
  '*.cap=92'
  '*.cr2=92'
  '*.cr3=92'
  '*.crw=92'
  '*.data=92'
  '*.dcr=92'
  '*.dcs=92'
  '*.dng=92'
  '*.drf=92'
  '*.dxf=92'
  '*.eip=92'
  '*.eps=92'
  '*.erf=92'
  '*.exr=92'
  '*.fff=92'
  '*.gif=92'
  '*.gpr=92'
  '*.heif=92'
  '*.ico=92'
  '*.iiq=92'
  '*.jpeg=92'
  '*.jpg=92'
  '*.jxl=92'
  '*.k25=92'
  '*.kdc=92'
  '*.kra=92'
  '*.mdc=92'
  '*.mef=92'
  '*.mos=92'
  '*.mrw=92'
  '*.nef=92'
  '*.nrw=92'
  '*.obm=92'
  '*.orf=92'
  '*.pbm=92'
  '*.pcx=92'
  '*.pef=92'
  '*.pgm=92'
  '*.png=92'
  '*.ppm=92'
  '*.psd=92'
  '*.ptx=92'
  '*.pxn=92'
  '*.qoi=92'
  '*.r3d=92'
  '*.raf=92'
  '*.raw=92'
  '*.rw2=92'
  '*.rwl=92'
  '*.rwz=92'
  '*.sr2=92'
  '*.srf=92'
  '*.srw=92'
  '*.svg=92'
  '*.tga=92'
  '*.tif=92'
  '*.tiff=92'
  '*.webp=92'
  '*.x3f=92'
  '*.xpm=92'
  '*.xvf=92'

  ## Audio
  '*.aac=92'
  '*.aif=92'
  '*.ape=92'
  '*.au=92'
  '*.flac=92'
  '*.m3u=92'
  '*.m4a=92'
  '*.mid=92'
  '*.midi=92'
  '*.mka=92'
  '*.mp3=92'
  '*.mpc=92'
  '*.oga=92'
  '*.ogg=92'
  '*.opus=92'
  '*.ra=92'
  '*.spx=92'
  '*.wav=92'
  '*.wma=92'
  '*.wv=92'
  '*.xspf=92'

  ## Video
  '*.avi=92'
  '*.flv=92'
  '*.h264=92'
  '*.m4v=92'
  '*.mkv=92'
  '*.mov=92'
  '*.mp4=92'
  '*.mpeg=92'
  '*.mpg=92'
  '*.ogv=92'
  '*.rm=92'
  '*.swf=92'
  '*.vob=92'
  '*.webm=92'
  '*.wmv=92'

  ## Font
  '*.fnt=92'
  '*.fon=92'
  '*.otf=92'
  '*.ttf=92'
  '*.woff2=92'
  '*.woff=92'

  ## 3d
  '*.3ds=92'
  '*.3mf=92'
  '*.alembic=92'
  '*.amf=92'
  '*.blend=92'
  '*.dae=92'
  '*.fbx=92'
  '*.hda=92'
  '*.hip=92'
  '*.iges=92'
  '*.igs=92'
  '*.ma=92'
  '*.mb=92'
  '*.mtl=92'
  '*.obj=92'
  '*.otl=92'
  '*.step=92'
  '*.stl=92'
  '*.stp=92'
  '*.usd=92'
  '*.usda=92'
  '*.usdc=92'
  '*.usdz=92'
  '*.wrl=92'
  '*.x3d=92'

  # Office (underlined green)
  '*.doc=4;92'
  '*.docx=4;92'
  '*.epub=4;92'
  '*.ics=4;92'
  '*.kex=4;92'
  '*.odp=4;92'
  '*.ods=4;92'
  '*.odt=4;92'
  '*.pdf=4;92'
  '*.pps=4;92'
  '*.ppt=4;92'
  '*.pptx=4;92'
  '*.ps=4;92'
  '*.rtf=4;92'
  '*.sxi=4;92'
  '*.sxw=4;92'
  '*.xlr=4;92'
  '*.xls=4;92'
  '*.xlsx=4;92'

  # Archives or compressed (magenta)
  '*.7z=95'
  '*.ace=95'
  '*.alz=95'
  '*.apk=95'
  '*.arc=95'
  '*.arj=95'
  '*.aseprite-extension=95'
  '*.bag=95'
  '*.bin=95'
  '*.bz2=95'
  '*.bz=95'
  '*.cab=95'
  '*.cpio=95'
  '*.crate=95'
  '*.db=95'
  '*.deb=95'
  '*.dmg=95'
  '*.drpm=95'
  '*.dwm=95'
  '*.dz=95'
  '*.ear=95'
  '*.egg=95'
  '*.esd=95'
  '*.gz=95'
  '*.img=95'
  '*.iso=95'
  '*.jar=95'
  '*.lha=95'
  '*.lrz=95'
  '*.lz4=95'
  '*.lz=95'
  '*.lzh=95'
  '*.lzma=95'
  '*.lzo=95'
  '*.msi=95'
  '*.paq8n=95'
  '*.paq8o=95'
  '*.pkg=95'
  '*.pyz=95'
  '*.rar=95'
  '*.rpm=95'
  '*.rz=95'
  '*.sar=95'
  '*.swm=95'
  '*.t7z=95'
  '*.tar=95'
  '*.taz=95'
  '*.tbz2=95'
  '*.tbz=95'
  '*.tgz=95'
  '*.tlz=95'
  '*.toast=95'
  '*.txz=95'
  '*.tz=95'
  '*.tzo=95'
  '*.tzst=95'
  '*.udeb=95'
  '*.vcd=95'
  '*.war=95'
  '*.whl=95'
  '*.wim=95'
  '*.xbps=95'
  '*.xz=95'
  '*.z=95'
  '*.zip=95'
  '*.zoo=95'
  '*.zpaq=95'
  '*.zst=95'

  # Executable (red)
  '*.a=91'
  '*.bat=91'
  '*.com=91'
  '*.dll=91'
  '*.dylib=91'
  '*.exe=91'
  '*.ko=91'
  '*.so=91'

  # Unimportant
  ## Build artifacts
  '*.aux=37'
  '*.bbl=37'
  '*.bc=37'
  '*.bcf=37'
  '*.blg=37'
  '*.cache=37'
  '*.class=37'
  '*.dyn_hi=37'
  '*.dyn_o=37'
  '*.fdb_latexmk=37'
  '*.fls=37'
  '*.hi=37'
  '*.idx=37'
  '*.ilg=37'
  '*.in=37'
  '*.ind=37'
  '*.la=37'
  '*.lo=37'
  '*.o=37'
  '*.out=37'
  '*.pyc=37'
  '*.pyd=37'
  '*.pyo=37'
  '*.rlib=37'
  '*.rmeta=37'
  '*.scons_opt=37'
  '*.sconsign.dblite=37'
  '*.sty=37'
  '*.synctex.gz=37'
  '*.toc=37'
  '*.txt=37'

  ## Other
  '*.CFUserTextEncoding=37'
  '*.DS_Store=37'
  '*.bak=37'
  '*.crdownload=37'
  '*.ctags=37'
  '*.dpkg-dist=37'
  '*.dpkg-new=37'
  '*.dpkg-old=37'
  '*.dpkg-tmp=37'
  '*.git=37'
  '*.localized=37'
  '*.lock=37'
  '*.log=37'
  '*.old=37'
  '*.orig=37'
  '*.part=37'
  '*.pid=37'
  '*.rej=37'
  '*.rpmnew=37'
  '*.rpmorig=37'
  '*.rpmsave=37'
  '*.swn=37'
  '*.swo=37'
  '*.swp=37'
  '*.timestamp=37'
  '*.tmp=37'
  '*.ucf-dist=37'
  '*.ucf-new=37'
  '*.ucf-old=37'
  '*bun.lockb=37'
  '*go.sum=37'
  '*package-lock.json=37'
  '*stderr=37'
  '*stdin=37'
  '*stdout=37'
  '*~=37'
]
$env.LS_COLORS = $ls_colors | str join ':'
