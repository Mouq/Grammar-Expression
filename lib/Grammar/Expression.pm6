use Grammar::Expression::Table;
use Grammar::Expression::Actions;

role Grammar::Expression is Grammar {
    # Wants to be %.prec-table what `is` is supported
    has $!prec-table;
    method prec-table {
        $!prec-table //= Grammar::Expression::Table.new;
    }
    # Default -ish-es
    token termish    { <term>    }
    token infixish   { <infix>   }
    token prefixish  { <prefix>  }
    token postfixish { <postfix> }

    method new-prec(|p) { $.prec-table.new-prec(|p) }

    # XXX $save?
    method O($prec, *%extra) {
        my $cur := self.'!cursor_start_cur'();
        $cur.'!cursor_pass'($cur.from);
        $cur.match = ($.prec-table{$prec}, %extra).hash;
        export-cursor $cur;
    }

    method EXPR($preclvl?) {
        my $preclim = $.prec-table{$preclvl}<prec> if $preclvl;
        $preclim //= $.prec-table.loosest;
        my @termstack;
        my @opstack;
        my $termish = 'termish';

        my &reduce := -> {
            note "entering reduce with @termstack @termstack[]";
            my $op = pop @opstack;
            given $op<O><assoc> {
                when 'unary' {
                    my $arg = pop @termstack;
                    $op[0]  = $arg;
                    $op<OPER> = $op;
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

        my $here = self;
        my $last-term = False;
        loop {
            note("In loop, at $here.pos()");
            my $oldpos = $here.pos;
            $here = $here."!cursor_init"($here.target,:p($here.pos));
            my $termcur = $here."$termish"();

            note($here.pos);
note $termcur.pos;
            return export-cursor $termcur if $termcur.pos < 0;
            # if $termcur.pos < 0 or not $termcur or
            #     ($here.pos == $oldpos and $termish eq 'termish')
            # {
            #     die("Bogus term") if @opstack > 1;
            #     return $here;
            # }
            my $term-match = $here.MATCH();
            note($term-match);
            $termish = 'termish';
            # Interleave any prefix/postfix we might have found
            my @pre  = ($term-match<prefixish>:delete  // []).list;
            my @post = ($term-match<postfixish>:delete // []).list.reverse;
            while @pre and @post {
                my $postO = @post[0]<O>;
                my $preO  = @pre[0]<O>;
                if $postO<prec> lt $preO<prec> {
                    push @opstack, shift @post;
                }
                elsif $postO<prec> gt $preO<prec> {
                    push @opstack, shift @pre;
                }
                elsif $postO<uassoc> eq 'left' {
                    push @opstack, shift @post;
                }
                elsif $postO<uassoc> eq 'right' {
                    push @opstack, shift @pre;
                }
                else {
                    die "{@pre[0]<sym>} and {@post[0]<sym>} are not associative";
                }
            }
            push @opstack, |@pre, |@post;

            note("Moving on to infixes");
            push @termstack, $term-match<termish1>;
            # Leaving the following commented until
            # I understand it:
            # @termstack[*-1]<postfixish>:delete

            # last if $no-infix # This should be more generalized
            loop {
                $oldpos = $here.pos;
                #$here = $here.'!cursor_start_cur'().ws();
                $here = $here.ws;
                my @infix = $here.infixish;#$here.'!cursor_start_cur'().infixish();
                $last-term = True and last unless @infix;
                my $infix = @infix[0];
                $last-term = True and last unless $infix.pos > $oldpos;
                $infix .= MATCH;

                my $inO = $infix<O>;
                my Str $inprec = $inO<prec>;
                if not defined $inprec {
                    die 'Infix has no precedence information'; # Fix me
                }

                $last-term = True and last if $inprec le $preclim;

                # Does new infix (or terminator) force any reductions?
                while @opstack[*-1]<O><prec> gt $inprec {
                    reduce;
                }

                last if $inprec lt $.prec-table.loosest;

                if @opstack[*-1]<O><prec> eq $inprec {
                    my $assoc = 1;
                    given $inO<assoc> {
                        when 'non'   { $assoc = 0; }
                        when 'left'  { reduce; }
                        when 'right' { }
                        when 'unary' { }
                        when 'list'  { ... }
                        default {
                            die "Unknown associativity $_ for $infix<sym>";
                        }
                    }
                    if not $assoc {
                        die "{@opstack[*-1]<sym>} and $infix are non-associative and require parens";
                    }
                }

                $termish = $inO<nextterm> if $inO<nextterm>;
                push @opstack, $infix; # The Shift
                last;
            }
            last if $last-term;
        }
        note('Done with TERM');
        reduce while @opstack > 1;
        note('Done reducing');
        #if @termstack {
            #@termstack[0].from = self.pos;
            #@termstack[0].pos = $here.pos;
        #}
        #my $pos = $here.pos;
        #$here = self.'!cursor_start_cur'();
        #$here.'!cursor_pass'($pos);
        #nqp::bindattr_i($here, Cursor, '$!pos', $pos);
        #$here.match = @termstack.pop;
        #$here.'!reduce'('EXPR');
        $*ACTIONS.?EXPR(@termstack[0]);
        $here."!cursor_init"($here.target,:p($here.pos));
    }
}

sub export-cursor (Cursor $c, :$p = 0) { $c."!cursor_init"($c.target,:p($c.pos+$p)) }
