################################################################################
# Generic Flow v5.0 (February 2023)
################################################################################
#
# Copyright 2011-2023 Gennady Kirpichev (https://github.com/32xlr8/gflow.git)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################
# Filename: integration/language_gf.lua
# Purpose:  Language support for lite-xl text editor
# Filename: integration/bash.rc
# Purpose:  Resources file for bash shell
################################################################################
-- Lite-XL language syntax for Generic Flow
-- Put it under ~/.config/lite-xl/plugins/

syntax.add {
  name = "Generic Flow script",
  files = { "%.gf$" },
  headers = "^#!.*bin.*sh\n",
  comment = "#",
  patterns = {
    -- $# is a bash special variable and the '#' shouldn't be interpreted
    -- as a comment.
    { pattern = "$[%a_@*#][%w_]*",                type = "keyword2" },
    -- Comments
    { pattern = "#.*\n",                          type = "comment"  },
    -- Strings
    { pattern = { '"', '"', '\\' },               type = "string"   },
    -- { pattern = { "'", "'", '\\' },               type = "string"   },
    { pattern = { '`', '`', '\\' },               type = "string"   },
    -- Ignore numbers that start with dots or slashes
    { pattern = "%f[%w_%.%/]%d[%d%.]*%f[^%w_%.]", type = "number"   },
    -- Operators
    { pattern = "[!<>|&%[%]:=*]",                 type = "operator" },
    -- Match parameters
    { pattern = "%f[%S][%+%-][%w%-_:]+",          type = "function" },
    { pattern = "%f[%S][%+%-][%w%-_]+%f[=]",      type = "function" },
    -- Prevent parameters with assignments from been matched as variables
    {
      pattern = "%s%-%a[%w_%-]*%s+()%d[%d%.]+",
      type = { "function", "number" }
    },
    {
      pattern = "%s%-%a[%w_%-]*%s+()%a[%a%-_:=]+",
      type = { "function", "symbol" }
    },
    -- Match variable assignments
    { pattern = "[_%a][%w_]+%f[%+=]",              type = "keyword2" },
    -- Match variable expansions
    { pattern = "${.-}",                           type = "keyword2" },
    { pattern = "$[%d$%a_@*][%w_]*",               type = "keyword2" },
    -- Functions
    { pattern = "[%a_%-][%w_%-]*[%s]*%f[(]",       type = "function" },
    -- Everything else
    { pattern = "[%a_][%w_]*",                     type = "symbol"   },
  },
  symbols = {
    ["case"]      = "keyword",
    ["in"]        = "keyword",
    ["esac"]      = "keyword",
    ["if"]        = "keyword",
    ["then"]      = "keyword",
    ["elif"]      = "keyword",
    ["else"]      = "keyword",
    ["fi"]        = "keyword",
    ["while"]     = "keyword",
    ["do"]        = "keyword",
    ["done"]      = "keyword",
    ["for"]       = "keyword",
    ["break"]     = "keyword",
    ["continue"]  = "keyword",
    ["function"]  = "keyword",
    ["local"]     = "keyword",
    ["echo"]      = "keyword",
    ["return"]    = "keyword",
    ["exit"]      = "keyword",
    ["alias"]     = "keyword",
    ["test"]      = "keyword",
    ["cd"]        = "keyword",
    ["declare"]   = "keyword",
    ["enable"]    = "keyword",
    ["eval"]      = "keyword",
    ["exec"]      = "keyword",
    ["export"]    = "keyword",
    ["getopts"]   = "keyword",
    ["hash"]      = "keyword",
    ["history"]   = "keyword",
    ["help"]      = "keyword",
    ["jobs"]      = "keyword",
    ["kill"]      = "keyword",
    ["let"]       = "keyword",
    ["mapfile"]   = "keyword",
    ["printf"]    = "keyword",
    ["read"]      = "keyword",
    ["readarray"] = "keyword",
    ["pwd"]       = "keyword",
    ["select"]    = "keyword",
    ["set"]       = "keyword",
    ["shift"]     = "keyword",
    ["source"]    = "keyword",
    ["time"]      = "keyword",
    ["type"]      = "keyword",
    ["until"]     = "keyword",
    ["unalias"]   = "keyword",
    ["unset"]     = "keyword",
    ["true"]      = "literal",
    ["false"]     = "literal"
  }
}


function . { ls --color "$PWD"/* -1d; }
function .. { cd ..; pwd; ls --color "$PWD"/* -1d; }
function ... { cd ../..; pwd; ls --color; }

function ll { ls --color -ltra $@; }
function ld {
    DIR=$PWD
    while [ "$DIR" != "/" -a  "$DIR" != "." ]; do
      ls -ld $DIR
      DIR=$(dirname $DIR)
    done
}

function e { nedit $@ & }
function r { nedit -read $@ & }

function xb { xterm -fg '#AAAAAA' -bg '#110000' -xrm 'xterm.vt100.foreground:#AAAAAA' -xrm 'xterm.vt100.background:#000000' -xrm 'xterm.vt100.cursorColor:#AAAAAA' -xrm 'xterm.vt100.color0:#555555' -xrm 'xterm.vt100.color8:#888888' -xrm 'xterm.vt100.color1:#BB3333' -xrm 'xterm.vt100.color9:#FF4040' -xrm 'xterm.vt100.color2:#33AA33' -xrm 'xterm.vt100.color10:#66FF66' -xrm 'xterm.vt100.color3:#CCCC33' -xrm 'xterm.vt100.color11:#FFFF33' -xrm 'xterm.vt100.color4:#0066CC' -xrm 'xterm.vt100.color12:#3399FF' -xrm 'xterm.vt100.color5:#AA66AA' -xrm 'xterm.vt100.color13:#FF88FF' -xrm 'xterm.vt100.color6:#00CCCC' -xrm 'xterm.vt100.color14:#00FFFF' -xrm 'xterm.vt100.color7:#D5D5D5' -xrm 'xterm.vt100.color15:#FFFFFF' -xrm 'xterm.vt100.colorBD:#FFFFFF' & }
function xw { xterm -fg '#444444' -bg '#FFFFFF' -xrm 'xterm.vt100.foreground:#444444' -xrm 'xterm.vt100.background:#FFFFFF' -xrm 'xterm.vt100.cursorColor:#444444' -xrm 'xterm.vt100.color0:#AAAAAA' -xrm 'xterm.vt100.color8:#888888' -xrm 'xterm.vt100.color1:#AA0000' -xrm 'xterm.vt100.color9:#FF0000' -xrm 'xterm.vt100.color2:#008800' -xrm 'xterm.vt100.color10:#00CC00' -xrm 'xterm.vt100.color3:#777700' -xrm 'xterm.vt100.color11:#999900' -xrm 'xterm.vt100.color4:#005588' -xrm 'xterm.vt100.color12:#0088AA' -xrm 'xterm.vt100.color5:#885588' -xrm 'xterm.vt100.color13:#AA88AA' -xrm 'xterm.vt100.color6:#008888' -xrm 'xterm.vt100.color14:#00AAAA' -xrm 'xterm.vt100.color7:#222222' -xrm 'xterm.vt100.color15:#000000' -xrm 'xterm.vt100.colorBD:#000000' & }
