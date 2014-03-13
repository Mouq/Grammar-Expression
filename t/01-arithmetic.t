use Test;
use Grammar::Expression;

grammar Arithmetic does Grammar::Expression {
    token TOP {
        {
            # self.new-prec($str) makes $str a new
            # precedence level and by default the
            # loosest level.
            $.new-prec('sign', :uassoc<left>);
            $.new-prec('exponential', :assoc<right>);
            $.new-prec('multiplicative', :assoc<left>);
            $.new-prec('additive', :assoc<left>);
            $.new-prec('mantissa', :tightest);
        }
        <EXPR>
    }

    # <EXPR> operates as:
    # [ <prefixish>* <termish> <postfixish>* ] +% <infixish>
    # --> Or should this be editable?
    #     (in this case »… <termish> <postfixish>? ] …«)
    token termish { <prefixish>* <term> {note 'invoked and matched'} <postfixish>? }
    rule term { <digit> | \( ~ \) <EXPR> }
    token digit { \d+ [\. \d+]? }

    token infixish { <infix> }

    proto token infix {*}
    token infix:sym<^> { <sym> <O('exponential')> }
    token infix:sym<*> { <sym> <O('multiplicative')> }
    token infix:sym</> { <sym> <O('multiplicative')> }
    token infix:sym<+> { <sym> <O('additive')> }
    token infix:sym<-> { <sym> <O('additive')> }

    token prefixish { <prefix> }

    proto token prefix {*}
    token prefix:sym<+> { <sym> <O('sign')> }
    token prefix:sym<-> { <sym> <O('sign')> }

    token postfixish { <[eE]> <EXPR('sign')> <O('mantissa')> }
}
class ArithActions does Grammar::Expression::Actions {
    method TOP ($/) { make $<EXPR>.ast }
    method term ($/) {
        make $<digit>
          ?? +$<digit>.Str
          !! $<EXPR>.ast
    }
    method infixish ($/) { make $<infix>.ast }
    method infix:sym<^> ($/) { make {$^a ** $^b} }
    method infix:sym<*> ($/) { make {$^a * $^b} }
    method infix:sym</> ($/) { make {$^a / $^b} }
    method infix:sym<+> ($/) { make {$^a + $^b} }
    method infix:sym<-> ($/) { make {$^a - $^b} }

    method prefixish ($/) { make $<prefix>.ast }
    method prefix:sym<+> ($/) { make { $^a } }
    method prefix:sym<-> ($/) { make { 0 - $^a } }

    method postfixish ($/) { make { $^a * 10 ** $<EXPR>.ast } }
}

my &arith = { Arithmetic.parse(:actions(ArithActions), $^str).?ast };
is arith('3 + 4'), 7;
is arith('3 + 4 * 2 / ( 1 - 5 ) ^ 2 ^ 3'), 3 + 4 * 2 / (1 - 5) ** 2 ** 3;
is arith('3e5'), 300000;
is arith('+3.1E-7'), 3.1e-7;

# vim: ft=perl6
