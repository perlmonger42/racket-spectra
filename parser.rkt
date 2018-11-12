#lang brag
spectra-program : @token-list
statement-list  : [statement-list ";"] statement
statement       : assignment | print
print           : "say" expr ";"

assignment      : /"var" id /"=" expr
@expr           : comparison
comparison      : [comparison ("!=" | "==" | "<" | ">" | "<=" | ">=")] additive
additive        : [additive ("+" | "-")] multiplicative
multiplicative  : [multiplicative ("*" | "/")] value
@value          : id | literal | /"(" expr /")" | value "[" expr "]"

id              : IDENTIFIER
literal         : INTEGER-LITERAL
                | REAL-LITERAL
                | RAW-STRING-LITERAL | RAW-STRING-LITERAL-ERR
                | Q-STRING-LITERAL | Q-STRING-LITERAL-ERR
                | QQ-STRING-LITERAL | QQ-STRING-LITERAL-ERR
                ;

token-list      : spectra-token*
spectra-token   : whitespace
                | literal | identifier | keyword | punctuation | operator
                | unexpected
                ;
 whitespace      : NEWLINE | WHITESPACE | COMMENT
                 ;
 identifier      : IDENTIFIER
                 ;
 keyword         : "fn" | "var" | "if" | "while" | "return"
                 ;
 punctuation     : "=" | ";" | "{" | "}" | "[" | "]"
                 | ":" | "," | "(" | ")"
                 ;
 operator        : "==" | "!="
                 | "+" | "-" | "/" | "*"
                 | "++"
 unexpected      : UNEXPECTED-CHAR
                 ;
