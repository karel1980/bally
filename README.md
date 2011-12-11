# Introduction
Bally is a simple game (Work in progress).

A ball rolls over a board.
When the ball rolls over an arrow, it proceeds
in the direction of the arrow.
You have to turn the arrows around so the ball ends up at the goal.

# To generate the images:
apt-get install povray imagemagick
cd images; ./generate-images.sh

# To play the game:
apt-get install ruby-gtk2
ruby bally.rb
