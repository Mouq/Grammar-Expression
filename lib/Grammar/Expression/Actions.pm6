role Grammar::Expression::Actions {
    method EXPR ($/) {
        my &reduce = $<OPER>.ast;
        make reduce |$/.list».ast;
    }
    
    method termish    ($/) { make $<term>.ast    }
    method infixish   ($/) { make $<infix>.ast   }
    method postfixish ($/) { make $<postfix>.ast }
    method prefixish  ($/) { make $<prefix>.ast  }
}
