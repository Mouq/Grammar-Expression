use Grammar::Expression::Table;
use Grammar::Expression::Actions;

role Grammar::Expression is Grammar {
    has Grammar::Expression::Table $.precedence-table .= new;
    # Default -ish-es
    token termish    { <term>    }
    token infixish   { <infix>   }
    token prefixish  { <prefix>  }
    token postfixish { <postfix> }

    method new-prec(|p) { $.precedence-table(|p) }

    method EXPR(Str $prec?) { ... }

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
