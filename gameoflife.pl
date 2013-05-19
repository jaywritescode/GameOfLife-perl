#!/usr/bin/perl -w

use POSIX;

my $filename = $ARGV[0] or die "Usage: perl gameoflife.pl [filename.rle]\n\n";
my ( $grid, $born, $survives ) = load($filename); 
															# represents the cells in the part of the plane that we're interested in
															#
															# @grid = ([array_ref_1], [array_ref_2],... [array_ref_n])
															# assume that for all 0 < i,j <= n, $#{$grid[i]} == $#{$grid[j]}
															# [array_ref_k] represents the cells in row k in the part of the plane we're interested in
															# (@grid[0][k], @grid[1][k],... @grid[n-1][k]) represents the cells in column k in the part of the
															#      infinite plane that we're interested in
print_grid();
my $minNeighborsForBirth;

for ( $i = 0 ; $i < 9 ; ++$i ) {
	if ( $born[$i] ) {
		$minNeighborsForBirth = $i;
		last;
	}
}

my $iteration = 0;

my $magnify = 1;

my $xleft = ceil( -( @{ $grid[0] } / 2 ) );					# x-coord of the leftmost cells in the grid
my $xright = $xleft + $#{ $grid[0] };						# x-coord of the rightmost cells in the grid
my $ytop = ceil( -( @grid / 2 ) );							# y-coord of the topmost cells in the grid
my $ybottom = $ytop + $#grid;								# y-coord of the bottommost cells in the grid

use Tk;

my $mw = new MainWindow;
$mw->configure( -title => "Conway's Game of Life" );
my $buttonFrame = $mw->Frame()->pack( -side => 'bottom', -expand => 1, -fill => 'x' );
my $magnifyMenu = $buttonFrame->Optionmenu(
	-options => [ [ '1x', 1 ], [ '2x', 2 ], [ '4x', 4 ], [ '5x', 5 ], [ '8x', 8 ] ],
	-variable => \$magnify_amt,
	-command  => sub {
		$magnify = $magnify_amt;
		draw_grid() if defined($canvas);
	})->pack( -side => 'right' );
my $nextButton = $buttonFrame->Button(
	-text    => "Next",
	-command => sub {
		next_iter();
		draw_grid();
	})->pack( -fill => 'x' );
our $canvas =
  $mw->Canvas( -height => 400, -width => 400 )->pack( -expand => 1, -fill => 'both' );
$canvas->after( 1200, \&draw_grid );
MainLoop;

sub next_iter {

															# first, add an extra row or column of cells on the top, bottom, left, or right
															# of the grid if necessary
	unless ( $minNeighborsForBirth > 3 ) {
		unless ( @grid < $minNeighborsForBirth )
		{													# if the grid has fewer than $minNeighborsForBirth rows, then we know that the
															#     cells in column $xleft - 1 or column $xright + 1 can't be turned on

			for $col ( ( 0, -1 ) )
			{												# let c be a cell on the left ($col == 0) or right ($col == -1) border
				for $row ( 1 .. $#grid - 1 ) {

															# then count how many of c, the cell north of c, and the cell south of
															#     c are alive. if that number is greater than or equal to $minNeighborsForBirth,
															#     we know at least one cell outside the border will be live...
					if ( $grid[ $row - 1 ][$col] + $grid[$row][$col] + $grid[ $row + 1 ][$col] >= $minNeighborsForBirth )
					{
						for $row ( 0 .. $#grid )
						{ # ...so put an extra cell at the right (or left, as appropriate) end of each column
							if ( $col == 0 ) {
								unshift @{ $grid[$row] }, 0;
							}
							else {
								push @{ $grid[$row] }, 0;
							}
						}
						$col
						  ? ++$xright
						  : --$xleft
						  ;    # and record the fact that the grid is expanding
						last;
					}
				}
			}
		}

		$col_count = @{ $grid[0] };
		unless ( $col_count < $minNeighborsForBirth )
		{													# similarly, determine if we need to expand the grid vertically by adding (an)
															# additional row(s) at the top or bottom
			for $row ( ( 0, -1 ) ) {
				for $col ( 1 .. $#{ $grid[0] } - 1 ) {
					if ( $grid[$row][ $col - 1 ] +
						$grid[$row][$col] +
						$grid[$row][ $col + 1 ] >= $minNeighborsForBirth )
					{
						if ( $row == 0 ) {
							unshift @grid, [ (0) x $col_count ]; 
															# [(0) x $col_count] returns an arrayref to an array of $col_count zeroes
							--$ytop;
							last;
						}
						else {
							push @grid, [ (0) x $col_count ];
							++$ybottom;
							last;
						}
					}
				}
			}
		}
	}

	my $row_count = @grid;
	my $live_neighbors;
	my @buffer;

	for $row ( 0 .. $row_count - 1 )
	{														# iterate over the grid and determine how many live neighbors each cell has
		for $col ( 0 .. $col_count - 1 ) {
			$live_neighbors = 0;
			for $delta_row ( -1 .. 1 ) {
				next
				  if $row + $delta_row < 0 || $row + $delta_row >= $row_count;
				for $delta_col ( -1 .. 1 ) {
					next if $delta_row == 0 && $delta_col == 0;
					next
					  if $col + $delta_col < 0
						  || $col + $delta_col >= $col_count;

					$live_neighbors += $grid[ $row + $delta_row ][ $col + $delta_col ];
				}
			}

															# based on how many live neighbors the cell has, the game rules, and the cell's
															# current state, determine the state of the cell in the next iteration...
															# then store that information in a buffer, because we need to retain the cell's
															# current state for a little while
			push @buffer,
			  {
				row  => $row,
				col  => $col,
				bool => $grid[$row][$col]
				? $survives[$live_neighbors]
				: $born[$live_neighbors]
			  };

															# once we've calculated and stored the next state of cell c, then we can actually
															# update the state of the cell northwest of cell c (assuming that we're iterating
															# over the grid from north to south, then west to east).
			if ( @buffer > $col_count + 2 ) {
				$_ = shift @buffer;
				$grid[ $_->{'row'} ][ $_->{'col'} ] = $_->{'bool'};
			}
		}
	}
	while ( $_ = shift @buffer )
	{														# update the states of the cells remaining in the buffer
		$grid[ $_->{'row'} ][ $_->{'col'} ] = $_->{'bool'};
	}

	print_grid();
	++$iteration;
	@grid;
}

sub draw_grid {
	$canvas->delete( $canvas->find( 'withtag', 'all' ) );

	my $x0 = $canvas->width / 2, $y0 = $canvas->height / 2;

	for $row ( $ytop .. $ybottom ) {
		for $col ( $xleft .. $xright ) {

			#   print '$row = ' . $row . ', $col = ' . $col . "\n";
			if ( $grid[ $row - $ytop ][ $col - $xleft ] ) {
				if ( $magnify == 1 ) {
					$canvas->createLine(
						$x0 + $col, $y0 + $row,
						$x0 + $col + 1,
						$y0 + $row + 1,
						-fill => 'black'
					);
				}
				else {
					$canvas->createRectangle(
						$x0 + ( $col * $magnify ),
						$y0 + ( $row * $magnify ),
						$x0 + ( ( $col + 1 ) * $magnify ),
						$y0 + ( ( $row + 1 ) * $magnify ),
						-fill => 'black'
					);
				}
			}
		}
	}
}

sub print_grid {
	print '-' x ( @{ $grid[0] } + 1 ) . "\n";
	for $row (@grid) {
		print "|";
		for $cell ( @{$row} ) {
			print $cell ? "x" : ".";
		}
		print "\n";
	}
}

sub load {
	use open IN => ":crlf";

	open( my $FH, '<', shift ) or die $!;
	while (<$FH>) {
		last unless m/^#.*/;
	}

	my $rex1 = qr<B([0-8]*)/S([0-8]*)>i, $rex2 = qr<([0-8]*)/([0-8]*)>;
	my $linerex =
	  qr<^x ?= ?([1-9]\d*), ?y ?= ?([1-9]\d*)(, ?rule ?= ($rex1|$rex2))?$>;

	m/$linerex/;
	my ( $width, $height ) = ( $1, $2 );

	# parse the rule string into arrays
	print "Rulestring: " . ( $4 || "B3/S23" ) . "\n";
	if ( defined $3 ) {
		@born     = (0) x 9;
		@survives = (0) x 9;

		for ( $born = $5 || $8 ; $born ; $born = substr( $born, 1 ) ) {
			$born[ substr( $born, 0, 1 ) ] = 1;
		}
		for (
			$survives = $6 || $7 ;
			$survives ;
			$survives = substr( $survives, 1 )
		  )
		{
			$survives[ substr( $survives, 0, 1 ) ] = 1;
		}
	}
	else {
		@born     = ( 0, 0, 0, 1, 0, 0, 0, 0, 0 );
		@survives = ( 0, 0, 1, 1, 0, 0, 0, 0, 0 );
	}

	# take the rest of the file and turn it into one long string
	while (<$FH>) {
		chomp;
		$string .= $_;
		last if m/!$/;
	}
															# split that long string into individual row strings
	@rows = split( qr/\$/, $string );

	my $r = 0;
	foreach (@rows) {										# for each row...
		$_ .= '$';											# tack on a dollar sign to make the regexp below simpler
		my @row_grid = ();

		while (m/([1-9]\d*)?([bo\$])/)
		{													# break down the row string into <count><cell_live_status> units
			unless ( $2 eq '$' ) {
				$p = ( $2 eq 'o' ) ? 1 : 0;
				unless ($1) {
					push @row_grid, $p;
				}
				else {
					push @row_grid, ($p) x $1;
				}
			}
			else {
				push @row_grid, (0) x ( $width - scalar(@row_grid) );
				push @grid, \@row_grid;

				$count = 1;
				while ( $1 && $count++ < $1 ) {
					push @grid, [ (0) x $width ];
				}
			}

			$_ = substr $_, $+[0];							# trim the current <run_length><tag> combination from the left
															# end of the row string
		}
	}

	( \@grid, \@born, \@survives );
}
