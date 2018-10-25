#lang brag
spectra-program : spectra-token*
spectra-token   : whitespace
                | literal | identifier | keyword | punctuation | operator
                | unexpected
                ;
whitespace      : NEWLINE | WHITESPACE | COMMENT
                ;
literal         : INTEGER-LITERAL
                | REAL-LITERAL
                | RAW-STRING-LITERAL | RAW-STRING-LITERAL-ERR
                | Q-STRING-LITERAL | Q-STRING-LITERAL-ERR
                | QQ-STRING-LITERAL | QQ-STRING-LITERAL-ERR
                ;
identifier      : IDENTIFIER
                ;
keyword         : "fn" | "var" | "if" | "while" | "return"
                ;
punctuation     : "=" | ";" | "{" | "}"
                | ":" | "," | "(" | ")"
                | "//" | "/*" | "*/"
                ;
operator        : "==" | "!="
                | "+" | "-" | "/" | "*"
                | "++"
unexpected      : UNEXPECTED-CHAR
                ;
