# https://github.com/patorjk/figlet.js

# Some constants
$FULL_WIDTH = 0
$FITTING = 1 
$SMUSHING = 2
$CONTROLLED_SMUSHING = 3

function Get-SmushingRules {
    Param (
    $OldLayout,
    $NewLayout
    )

    $rules = @{}
    $codes = @(
      @(16384, "vLayout", $SMUSHING),
      @( 8192, "vLayout", $FITTING),
      @( 4096, "vRule5",  $true),
      @( 2048, "vRule4",  $true),
      @( 1024, "vRule3",  $true),
      @(  512, "vRule2",  $true),
      @(  256, "vRule1",  $true),
      @(  128, "hLayout", $SMUSHING),
      @(   64, "hLayout", $FITTING),
      @(   32, "hRule6",  $true),
      @(   16, "hRule5",  $true),
      @(    8, "hRule4",  $true),
      @(    4, "hRule3",  $true),
      @(    2, "hRule2",  $true),
      @(    1, "hRule1",  $true)
    )

    $val = if ($NewLayout -ne $null) { $NewLayout } else { $OldLayout }
    foreach ($code in $codes) {
      if ($val -gt $code[0]) {
        $val -= $code[0]
        if (-not ($rules.ContainsKey($code[1]))) {
          $rules[$code[1]] = $code[2]
        }
      } elseif (($code[1] -ne 'vLayout') -and ($code[1] -ne 'hLayout')) {
        $rules[$code[1]] = $false
      }
    }

    if (-not ($rules.ContainsKey('hLayout'))) {
      if ($OldLayout -eq 0) {
        $rules.hLayout = $FITTING
      } elseif ($OldLayout -eq -1) {
        $rules.hLayout = $FULL_WIDTH
      } else {
        if ($rules.hRule1 -or $rules.hRule2 -or $rules.hRule3 -or $rules.hRule4 -or $rules.hRule5 -or $rules.hRule6) {
          $rules.hLayout = $CONTROLLED_SMUSHING
        } else {
          $rules.hLayout = $SMUSHING
        }
      }
    } elseif ($rules.hLayout -eq $SMUSHING) {
      if ($rules.hRule1 -or $rules.hRule2 -or $rules.hRule3 -or $rules.hRule4 -or $rules.hRule5 -or $rules.hRule6) {
        $rules.hLayout = $CONTROLLED_SMUSHING
      }
    }

    if (-not ($rules.ContainsKey('vLayout'))) {
      if ($rules.vRule1 -or $rules.vRule2 -or $rules.vRule3 -or $rules.vRule4 -or $rules.vRule5) {
        $rules.vLayout = $CONTROLLED_SMUSHING
      } else {
        $rules.vLayout = $FULL_WIDTH
      }
    } elseif ($rules.vLayout -eq $SMUSHING) {
      if ($rules.vRule1 -or $rules.vRule2 -or $rules.vRule3 -or $rules.vRule4 -or $rules.vRule5) {
        $rules.vLayout = $CONTROLLED_SMUSHING
      }
    }

    return $rules
}

# The [vh]Rule[1-6]_Smush functions return the smushed character OR false if 
# the two characters can't be smushed


function hRule1_Smush {
<#
.Synopsis
    Rule 1: EQUAL CHARACTER SMUSHING (code value 1)

.Description
    Two sub-characters are smushed into a single sub-character
    if they are the same. This rule does not smush hardblanks.
    (See rule 6 on hardblanks below)

#>
    Param(
    $ch1,
    $ch2,
    $hardBlank
    )
    if (($ch1 -eq $ch2) -and ($ch1 -ne $hardBlank)) { return $ch1 }
    return $false
}

function hRule2_Smush {
<#
.Synopsis
    Rule 2: UNDERSCORE SMUSHING (code value 2)

.Description
    An underscore ("_") will be replaced by any of: "|", "/",
    "\", "[", "]", "{", "}", "(", ")", "<" or ">".
#>
    Param(
    $ch1,
    $ch2
    )
    $rule2str = '|/\\[]{}()<>'

    if ($ch1 -eq '_') {
      if ($rule2str.IndexOf($ch2) -ne -1) { return $ch2 }
    } elseif ($ch2 -eq '_') {
      if ($rule2str.IndexOf($ch1) -ne -1) { return $ch1 }
    }
    return $false
}

function hRule3_Smush {
<#
.Synopsis
    Rule 3: HIERARCHY SMUSHING (code value 4)

.Description
    A hierarchy of six classes is used: "|", "/\", "[]", "{}",
    "()", and "<>".  When two smushing sub-characters are
    from different classes, the one from the latter class
    will be used.
#>
    Param(
    $ch1,
    $ch2
    )
    $rule3Classes = '| /\\ [] {} () <>'
    $r3_pos1 = $rule3Classes.IndexOf($ch1)
    $r3_pos2 = $rule3Classes.IndexOf($ch2)
    if (($r3_pos1 -ne -1) -and ($r3_pos2 -ne -1)) {
      if (($r3_pos1 -ne $r3_pos2) -and ([Math]::Abs($r3_pos1 - $r3_pos2) -ne 1)) {
        return $rule3Classes.Substring([Math]::Max($r3_pos1, $r3_pos2), 1)
      }
    }
    return $false
}

$FULL_WIDTH = 0
$FITTING = 1
$SMUSHING = 2
$CONTROLLED_SMUSHING = 3


function hRule4_Smush {
<#
.Synopsis
    Rule 4: OPPOSITE PAIR SMUSHING (code value 8)
.Description
    Smushes opposing brackets ("[]" or "]["), braces ("{}" or
    "}{") and parentheses ("()" or ")(") together, replacing
    any such pair with a vertical bar ("|").
#>
    Param($ch1,$ch2)
    $rule4Str = '[] {} ()'
    $r4_pos1 = $rule4Str.IndexOf($ch1)
    $r4_pos2 = $rule4Str.IndexOf($ch2)
    if (($r4_pos1 -ne -1 ) -and ($r4_pos2 -ne -1)) {
      if ([Math]::Abs($r4_pos1 - $r4_pos2) -le 1) {
        return '|'
      }
    }
    return $false
}

function hRule5_Smush {
<#
.Synopsis
    Rule 5: BIG X SMUSHING (code value 16)
.Description
    Smushes "/\" into "|", "\/" into "Y", and "><" into "X".
    Note that "<>" is not smushed in any way by this rule.
    The name "BIG X" is historical; originally all three pairs
    were smushed into "X".
#>
    Param($ch1,$ch2)
    $rule5Str = '/\ \/ ><'
    $rule5Hash = @{ 0 ='|'; 3 = 'Y'; 6 = 'X' }
    $r5_pos1 = $rule5Str.IndexOf($ch1)
    $r5_pos2 = $rule5Str.IndexOf($ch2)
    if (($r5_pos1 -ne -1 ) -and ($r5_pos2 -ne -1)) {
      if (($r5_pos2 - $r5_pos1) -eq 1) {
        return $rule5Hash[$r5_pos1]
      }
    }
}

function hRule6_Smush {
<#
.Synopsis
    Rule 6: HARDBLANK SMUSHING (code value 32)
.Description
    Smushes two hardblanks together, replacing them with a
    single hardblank.  (See "Hardblanks" below.)
#>
    Param($ch1,$ch2,$hardBlank)
    if (($ch1 -eq $hardBlank) -and ($ch2 -eq $hardBlank)) {
      return $hardBlank
    }
    return $false
}

function vRule1_Smush {
<#
.Synopsis
    Rule 1: EQUAL CHARACTER SMUSHING (code value 256)
.Description
    Same as horizontal smushing rule 1.
#>
    Param($ch1,$ch2)
    if ($ch1 -eq $ch2) { return $ch1 }
    return $false
}

function vRule2_Smush {
<#
.Synopsis
    Rule 2: UNDERSCORE SMUSHING (code value 512)
.Description
    Same as horizontal smushing rule 2.
#>
    Param($ch1,$ch2)
    $rule2Str = '|/\\[]{}()<>'
    if ($ch1 -eq '_') {
      if ($rule2Str.IndexOf($ch2) -ne -1) { return $ch2 }
    } elseif ($ch2 -eq '_') {
      if ($rule2Str.IndexOf($ch1) -ne -1) { return $ch1 }
    }
    return $false
}

function vRule3_Smush {
<#
.Synopsis
    Rule 3: HIERARCHY SMUSHING (code value 1024)
.Description
    Same as horizontal smushing rule 3.
#>
    Param($ch1,$ch2)

    $rule3Classes = '| /\\ [] {} () <>'
    $r3_pos1 = $rule3Classes.IndexOf($ch1)
    $r3_pos2 = $rule3Classes.IndexOf($ch2)
    if (($r3_pos1 -ne -1) -and ($r3_pos2 -ne -1)) {
      if (($r3_pos1 -ne $r3_pos2) -and [Math]::Abs($r3_pos1 - $r3_pos2) -ne 1) {
        return $rule3Classes.Substring([Math]::Max($r3_pos1,$r3_pos2), 1)
      }
    }
    return $false
}

function vRule4_Smush {
<#
.Synopsis
    Rule 4: HORIZONTAL LINE SMUSHING (code value 2048)
.Description
    Smushes stacked pairs of "-" and "_", replacing them with
    a single "=" sub-character.  It does not matter which is
    found above the other.  Note that vertical smushing rule 1
    will smush IDENTICAL pairs of horizontal lines, while this
    rule smushes horizontal lines consisting of DIFFERENT
    sub-characters.
#>
    Param($ch1,$ch2)
    if ( (($ch1 -eq '-') -and ($ch2 -eq '_')) -or (($ch1 -eq '_') -and ($ch2 -eq '-')) ) {
      return '='
    }
    return $false
}

function vRule5_Smush {
<#
.Synopsis
    Rule 5: VERTICAL LINE SUPERSMUSHING (code value 4096)
.Description
    This one rule is different from all others, in that it
    "supersmushes" vertical lines consisting of several
    vertical bars ("|").  This creates the illusion that
    FIGcharacters have slid vertically against each other.
    Supersmushing continues until any sub-characters other
    than "|" would have to be smushed.  Supersmushing can
    produce impressive results, but it is seldom possible,
    since other sub-characters would usually have to be
    considered for smushing as soon as any such stacked
    vertical lines are encountered.
#>
    Param($ch1,$ch2)

    if (($ch1 -eq '|') -and ($ch2 -eq '|')) {
      return '|'
    }
    return $false
}

function uni_Smush {
<#
.Synopsis
    Universal smushing
.Description
    Universal smushing simply overrides the sub-character from the
    earlier FIGcharacter with the sub-character from the later
    FIGcharacter.  This produces an "overlapping" effect with some
    FIGfonts, wherin the latter FIGcharacter may appear to be "in
    front".
#>
    Param($ch1,$ch2,$hardBlank)

    if (($ch2 -eq ' ') -or ($ch2 -eq '')) {
      return $ch1
    } elseif (($ch2 -eq $hardBlank) -and ($ch1 -ne ' ')) {
      return $ch1
    } else {
      return $ch2
    }
}

<# ----- main vertical smush routines (excluding rules) ----- #>

function canVerticalSmush {
<#
.Synopsis
    Determines if two lines can be vertically smushed
.Description
    Takes in two lines of text and returns one of the following:

    "valid" - These lines can be smushed together given the current smushing rules
    "end" - The lines can be smushed, but we're at a stopping point
    "invalid" - The two lines cannot be smushed together
#>
    Param(
    # A line of text
    $txt1,
    # A line of text
    $txt2,
    # Figlet options array
    $opts
    )

    if ($opts.fittingRules.vLayout -eq $FULL_WIDTH) { return 'invalid' }
    $len = [Math]::Min($txt1.Length, $txt2.Length)
    if ($len -eq 0) { return 'invalid' }

    $endSmush = $false

    for ($ii = 0; $ii -lt $len; $ii++) {
      $ch1 = $txt1.Substring($ii,1)
      $ch2 = $txt2.Substring($ii,1)
      if (($ch1 -eq ' ') -and ($ch2 -eq ' ')) {
        if ($opts.fittingRules.vLayout -eq $FITTING) {
          return 'invalid'
        } elseif ($opts.fittingRules.vLayout -eq $SMUSHING) {
          return 'end'
        } else {
          if ( (vRule5_Smush $ch1 $ch2) -ne $false ) {
            # This jScript-ism is not needed as endSmush is initialized already
            # keeping the comment so the code tracks.
            # $endsmush = ($endsmush -or $false)
            continue
          }
          $validSmush = $false
          $validSmush = if ($opts.fittingRules.vRule1) { vRule1_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule2) { vRule2_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule3) { vRule3_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule4) { vRule4_Smush $ch1 $ch2 } else { $validSmush }
          $endSmush = $true
          if (-not $validSmush) { return 'invalid' }
        }
      }
    }
    if ($endSmush) {
      return 'end'
    } else {
      return 'valid'
    }
}

function getVerticalSmushDist {
    Param(
    $lines1,
    $lines2,
    $opts
    )

    $maxDist = $line1.Length
    $len1 = $lines1.Length
    $len2 = $lines2.Length
    $curDist = 1

    while ($curDist -le $maxDist) {
      #KWH: Place I may have gotten the Port wrong
      $subLines1 = $lines1[([Math]::Max(0,$len1 - $curDist)), $len1 - 1]  #slice
      $subLines2 = $lines2[0, ([Math]::Min($maxDist, $curDist)) - 1]  #slice
      $slen = $subLines2.Length
      $result = ""
      for ($ii = 0; $ii -lt $slen; $ii++) {
        $ret = canVerticalSmush $subLines1[$ii] $subLines2[$ii] $opts
        if ($ret -eq 'end') {
          $result = $ret
        } elseif ($ret -eq 'invalid') {
          $result = $ret
          break
        } else {
          if ($result -eq '') {
            $result = 'valid'
          }
        }
      }

      if ($result -eq 'invalid') { $curDist--; break }
      if ($result -eq 'end') { break }
      if ($result -eq 'valid') { $curDist++}
    }

    return [Math]::Min($maxDist, $curDist)
}

function verticallySmushLines {
    Param(
    $line1,
    $line2,
    $opts
    )

    $len = [Math]::Min($line1.Length, $line2.Length)
    $result = ""

    for ($ii = 0; $ii -lt $len; $ii++) {
      $ch1 = $line1.Substring($ii,1)
      $ch2 = $line2.Substring($ii,1)
      if (($ch1 -ne ' ') -and ($ch2 -ne ' ')) {
        if ($opts.fittingRules.vLayout -eq $FITTING) {
          $result += uni_Smush $ch1 $ch2
        } elseif ($opts.fittingRules.vLayout -eq $SMUSHING) {
          $result += uni_Smush $ch1 $ch2
        } else {
          $validSmush = if ($opts.fittingRules.vRule5) { vRule5_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule1) { vRule1_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule2) { vRule2_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule3) { vRule3_Smush $ch1 $ch2 } else { $validSmush }
          $validSmush = if ((-not $validSmush) -and $opts.fittingRules.vRule4) { vRule4_Smush $ch1 $ch2 } else { $validSmush }
          $result += $validSmush
        }
      } else {
        $result += uni_Smush $ch1 $ch2
      }
    }

    return $result
}

function verticalSmush {
    Param(
    $lines1,
    $lines2,
    $overlap,
    $opts
    )

    $len1 = $lines1.Length
    $len2 = $lines2.Length
    $piece1 = $lines1[0..([Math]::Max(0,$len1 - $overlap) - 1)] #slice
    $piece2_1 = $lines1[([Math]::Max(0,$len1 - $overlap)), ($len1 - 1)] #slice
    $piece2_2 = $lines2[0, ([Math]::Min($overlap, $len2) - 1)] #slice
    $piece2 = @()
    $result = @()
    $len = $piece2_1.Length
    for ($ii = 0; $ii -lt $len; $i++) {
      if ($ii -ge $len2) {
        $line = $piece2_1[$ii]
      } else {
        $line = verticallySmushLines $piece2_1[$ii] $piece2_2[$ii] $opts
      }
      $piece2 += $line # push
    }
    $piece3 = $lines2[([Math]::Min($overlap, $len2)), ($len2 - 1)] # slice

    return ($piece1,$piece2,$piece3) # concat
}

function padLines {
    Param(
    $lines,
    $numSpaces
    )

    $len = $lines.Length
    $padding = ''
    for ($ii = 0; $ii -lt $numSpaces; $ii++) {
      $padding += ' '
    }
    for ($ii = 0; $ii -lt $len; $ii++) {
      $lines[$ii] += $padding
    }

    # No return here, so guessing $lines is byref, probably want to handle as a return (easier than messing with ref)?
    # Need to remember to change the call; only used in smushVerticalFigLines
    $lines
}

function smushVerticalFigLines {
    Param(
    $output,
    $lines,
    $opt
    )

    $len1 = $output[0].Length
    $len2 = $lines[0].Length
    if ($len1 -gt $len2) {
      $lines = padLines $lines ($len1 - $len2)
    } elseif ($len2 -gt $len1) {
      $output = padLines $output ($len2 - $len1)
    }
    $overlap = getVerticalSmushDist $output $lines $opts

    # guessing that this is supposed to have a sideeffect of changing $lines and $output

    return (verticalSmush $output $lines $overlap $opt)
}
<#



#>
