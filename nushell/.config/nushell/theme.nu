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
