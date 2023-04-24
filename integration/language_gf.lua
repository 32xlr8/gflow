################################################################################
# Generic Flow v5.1 (May 2023)
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
################################################################################
-- mod-version:3
local syntax = require "core.syntax"

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
