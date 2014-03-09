use Grammar::Expression::Table;
use Grammar::Expression::Actions;

role Grammar::Expression is Grammar {
    # Wants to be %.prec-table what `is` is supported
    has Grammar::Expression::Table $.prec-table .= new;
    # Default -ish-es
    token termish    { <term>    }
    token infixish   { <infix>   }
    token prefixish  { <prefix>  }
    token postfixish { <postfix> }

    method new-prec(|p) { $.prec-table(|p) }

    # XXX $save?
    method O($prec, *%extra) {
        my $cur := self.'!cursor_start_cur'();
        $cur.'!cursor_pass'($cur.from));
        $cur.match = ($.prec-table{$prec}, %extra).hash;
        $cur;
    }

    method EXPR($preclvl?) {
        my $preclim = $.prec-table{$preclvl}<prec> if $preclvl
        $preclim //= $.prec-table.loosest;
        my @termstack;
        my @opstack;
        my $termish = 'termish';

        my &reduce := -> {
            my $op = pop @opstack;
            given $op<O><assoc> {
                when 'unary' {
                    my $arg = pop @termstack;
                    $op[0]  = $arg;
                    #$key    = $arg.from < $op.from
                    #        ?? 'postfixish'
                    #        !! 'prefixish';
                }
                when 'list' { ... }
                default {
                    $op[1] = pop @termstack; # right
                    $op[0] = pop @termstack; # left
                    #$key  = 'infixish';
                }
            }
            $*ACTIONS.?EXPR($op);
        }

        ...;
    }

    method parse($target, :$actions = Mu, |p) {
        if $actions.^name ne 'Mu' and $actions !~~ Grammar::Expression::Actions {
            # XXX Less hacky way to do this?
            # (needs to have $actions second so
            # G::P::A doesn't override methods)
            $actions = Grammar::Expression::Actions
                       but role :: is $actions {}
        }
        callsame(:$actions, $target, |p);
    }
    method subparse($target, :$actions = Mu, |p) {
        if $actions.^name ne 'Mu' and $actions !~~ Grammar::Expression::Actions {
            # XXX Same as parse
            $actions = Grammar::Expression::Actions
                       but role :: is $actions {}
        }
        callsame(:$actions, $target, |p);
    }
}
