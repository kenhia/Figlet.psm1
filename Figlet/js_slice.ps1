<#
   Adding this to the repo for now, won't be needed in the final as the function
   will be in the module file, but I probably got something off here and this
   will remind me what I was doing and give me a place to figure out where I
   went wrong.
#>

function Get-JavaArraySlice {
<#
.Synopsis
  Implement something close to JavaScripts Array.slice()
.Notes
https://tc39.github.io/ecma262/#sec-array.prototype.slice
#>
    Param(
    [Parameter(Mandatory)]
    [Object[]]$Array,
    [int]$Start,
    [int]$End
    )
    $len = $Array.Length
    $relativeStart = $Start

    if ($relativeStart -lt 0) {
      $k = [Math]::Max(($len - $relativeStart), 0)
    } else {
      $k = [Math]::Min($relativeStart, $len)
    }

    if ($End -eq $null) {
      $relativeEnd = $len
    } else {
      $relativeEnd = $End
    }

    if ($relativeEnd -lt 0) {
      $final = [Math]::Max(($len + $relativeEnd), 0)
    } else {
      $final = [Math]::Min($relativeEnd, $len)
    }

    $count = [Math]::Max($final - $k, 0)

    Write-Host "k:$k final:$final count:$count"
    if ($count -eq 0) {
      @()
    } else {
      $Array[$k..($k+$count-1)]
    }
}

$myArray = @('A', 'B', 'C', 'D', 'E')
Get-JavaArraySlice $myArray 1 -1


<#

https://tc39.github.io/ecma262/#sec-array.prototype.slice

 1. Let O be ? ToObject(this value).
 2. Let len be ? ToLength(? Get(O, "length")).
 3. Let relativeStart be ? ToInteger(start).
 4. If relativeStart < 0, let k be max((len + relativeStart), 0); else let k be min(relativeStart, len).
 5. If end is undefined, let relativeEnd be len; else let relativeEnd be ? ToInteger(end).
 6. If relativeEnd < 0, let final be max((len + relativeEnd), 0); else let final be min(relativeEnd, len).
 7. Let count be max(final - k, 0).
 8. Let A be ? ArraySpeciesCreate(O, count).
 9. Let n be 0.
10. Repeat, while k < final
      a. Let Pk be ! ToString(k).
      b. Let kPresent be ? HasProperty(O, Pk).
      c. If kPresent is true, then
           i. Let kValue be ? Get(O, Pk).
          ii. Perform ? CreateDataPropertyOrThrow(A, ! ToString(n), kValue).
      d. Increase k by 1.
      e. Increase n by 1.
11. Perform ? Set(A, "length", n, true).
12. Return A.

#>