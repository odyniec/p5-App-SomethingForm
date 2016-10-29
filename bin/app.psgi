#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use App::SomethingForm;
App::SomethingForm->to_app;
