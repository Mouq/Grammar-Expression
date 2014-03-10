role Grammar::Expression::Actions {
    method EXPR ($/) {
        note('Hey, EXPR actually got called!');
        note("Here's what we got, doc: "~$/);
        my &reduce = $<OPER>.ast;
        make reduce |$/.list».ast;
    }
    
    method termish    ($/) { make $<term>.ast    }
    method infixish   ($/) { make $<infix>.ast   }
    method postfixish ($/) { make $<postfix>.ast }
    method prefixish  ($/) { make $<prefix>.ast  }
}
