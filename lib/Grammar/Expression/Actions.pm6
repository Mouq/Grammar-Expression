role Grammar::Expression::Actions {
    method EXPR ($/) {
        note('Hey, EXPR actually got called!');
        note("Here's what we got, doc: "~$/);
        if $<OPER> {
            my &reduce = $<OPER>.ast;
            make reduce |$/.list».ast;
        }
    }
    
    method termish    ($/) { make $<term>.ast    if $<term>    }
    method infixish   ($/) { make $<infix>.ast   if $<infix>   }
    method postfixish ($/) { make $<postfix>.ast if $<postfix> }
    method prefixish  ($/) { make $<prefix>.ast  if $<prefix>  }
}
