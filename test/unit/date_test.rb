require 'test_helper'

include HgvMetaIdentifierHelper

class DateTest < ActiveSupport::TestCase

  def setup

  end

  def test_century_qualifier
    chronFunction({
      '-0500-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '-0100-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '0001-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '0401-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},

      '-0401-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '0100-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '0500-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},

      '-0500-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMin},
      '-0100-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMin},
      '0001-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMin},
      '0401-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMin},

      '-0476-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMax},
      '-0076-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMax},
      '0025-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMax},
      '0425-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'beginning', :yq => '', :mq => '', :chron => :chronMax},

      '-0500-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMin},
      '-0100-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMin},
      '0001-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMin},
      '0401-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMin},

      '-0451-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMax},
      '-0051-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMax},
      '0050-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMax},
      '0450-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'first_half', :yq => '', :mq => '', :chron => :chronMax},

      '-0475-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMin},
      '-0075-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMin},
      '0026-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMin},
      '0426-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMin},

      '-0451-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMax},
      '-0051-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMax},
      '0050-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMax},
      '0450-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'first_half_to_middle', :yq => '', :mq => '', :chron => :chronMax},

      '-0475-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMin},
      '-0075-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMin},
      '0026-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMin},
      '0426-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMin},

      '-0426-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMax},
      '-0026-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMax},
      '0075-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMax},
      '0475-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'middle', :yq => '', :mq => '', :chron => :chronMax},

      '-0450-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMin},
      '-0050-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMin},
      '0051-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMin},
      '0451-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMin},

      '-0426-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMax},
      '-0026-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMax},
      '0075-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMax},
      '0475-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'middle_to_second_half', :yq => '', :mq => '', :chron => :chronMax},

      '-0450-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMin},
      '-0050-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMin},
      '0051-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMin},
      '0451-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMin},

      '-0401-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMax},
      '0100-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMax},
      '0500-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'second_half', :yq => '', :mq => '', :chron => :chronMax},

      '-0425-01-01' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMin},
      '-0025-01-01' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMin},
      '0076-01-01'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMin},
      '0476-01-01'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMin},

      '-0401-12-31' => {:c => '-5', :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '-1', :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMax},
      '0100-12-31'  => {:c => '1',  :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMax},
      '0500-12-31'  => {:c => '5',  :y => '', :m => '', :d => '', :cq => 'end', :yq => '', :mq => '', :chron => :chronMax}
    })
  end

  def test_year_qualifier
    chronFunction({
      '0001-01-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '1976-01-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '-0001-01-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '-1976-01-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMin},

      '0001-12-31'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '1976-12-31'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '-1976-12-31' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => '', :mq => '', :chron => :chronMax},

      '0001-01-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMin},
      '1976-01-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMin},
      '-0001-01-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMin},
      '-1976-01-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMin},

      '0001-03-31'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMax},
      '1976-03-31'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMax},
      '-0001-03-31' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMax},
      '-1976-03-31' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'beginning', :mq => '', :chron => :chronMax},

      '0001-01-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMin},
      '1976-01-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMin},
      '-0001-01-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMin},
      '-1976-01-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMin},

      '0001-06-30'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMax},
      '1976-06-30'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMax},
      '-0001-06-30' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMax},
      '-1976-06-30' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'first_half', :mq => '', :chron => :chronMax},

      '0001-04-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMin},
      '1976-04-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMin},
      '-0001-04-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMin},
      '-1976-04-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMin},

      '0001-06-30'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMax},
      '1976-06-30'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMax},
      '-0001-06-30' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMax},
      '-1976-06-30' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'first_half_to_middle', :mq => '', :chron => :chronMax},

      '0001-04-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMin},
      '1976-04-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMin},
      '-0001-04-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMin},
      '-1976-04-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMin},

      '0001-09-30'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMax},
      '1976-09-30'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMax},
      '-0001-09-30' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMax},
      '-1976-09-30' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'middle', :mq => '', :chron => :chronMax},

      '0001-07-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMin},
      '1976-07-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMin},
      '-0001-07-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMin},
      '-1976-07-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMin},

      '0001-09-30'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMax},
      '1976-09-30'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMax},
      '-0001-09-30' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMax},
      '-1976-09-30' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'middle_to_second_half', :mq => '', :chron => :chronMax},

      '0001-07-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMin},
      '1976-07-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMin},
      '-0001-07-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMin},
      '-1976-07-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMin},

      '0001-12-31'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMax},
      '1976-12-31'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMax},
      '-1976-12-31' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'second_half', :mq => '', :chron => :chronMax},

      '0001-10-01'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMin},
      '1976-10-01'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMin},
      '-0001-10-01' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMin},
      '-1976-10-01' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMin},

      '0001-12-31'  => {:c => '', :y => '1',     :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMax},
      '1976-12-31'  => {:c => '', :y => '1976',  :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMax},
      '-0001-12-31' => {:c => '', :y => '-1',    :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMax},
      '-1976-12-31' => {:c => '', :y => '-1976', :m => '', :d => '', :cq => '', :yq => 'end', :mq => '', :chron => :chronMax}
    })
  end

  def test_month_qualifier
    chronFunction({
      '-1976-01-01' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMin},
      '-0001-06-01' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMin},
      '0001-07-01'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMin},
      '1976-12-01'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMin},
      '-1976-01-11' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMin},
      '-0001-06-11' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMin},
      '0001-07-11'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMin},
      '1976-12-11'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMin},
      '-1976-01-21' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMin},
      '-0001-06-21' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMin},
      '0001-07-21'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMin},
      '1976-12-21'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMin},
      '-1976-01-10' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMax},
      '-0001-06-10' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMax},
      '0001-07-10'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMax},
      '1976-12-10'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'beginning', :chron => :chronMax},
      '-1976-01-20' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMax},
      '-0001-06-20' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMax},
      '0001-07-20'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMax},
      '1976-12-20'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'middle', :chron => :chronMax},
      '-1976-01-31' => {:c => '', :y => '-1976', :m => '1',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-0001-06-30' => {:c => '', :y => '-1',    :m => '6',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '0001-07-31'  => {:c => '', :y => '1',     :m => '7',  :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1976-12-31'  => {:c => '', :y => '1976',  :m => '12', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax}
    })
  end

  def test_leap_year
    chronFunction({
      '1600-02-29'  => {:c => '', :y => '1600', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1700-02-28'  => {:c => '', :y => '1700', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1800-02-28'  => {:c => '', :y => '1800', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1900-02-28'  => {:c => '', :y => '1900', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '2000-02-29'  => {:c => '', :y => '2000', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1976-02-29'  => {:c => '', :y => '1976', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '1977-02-28'  => {:c => '', :y => '1977', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},

      '-1600-02-29' => {:c => '', :y => '-1600', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},# is this really what we would exspect?
      '-1700-02-28' => {:c => '', :y => '-1700', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-1800-02-28' => {:c => '', :y => '-1800', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-1900-02-28' => {:c => '', :y => '-1900', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-2000-02-29' => {:c => '', :y => '-2000', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-1976-02-29' => {:c => '', :y => '-1976', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax},
      '-1977-02-28' => {:c => '', :y => '-1977', :m => '2', :d => '', :cq => '', :yq => '', :mq => 'end', :chron => :chronMax}
    })
  end

  def test_miscellaneous
    chronFunction({
      '0543-02-01'  => {:c => '6', :y => '543', :m => '2', :d => '1', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '0543-02-01'  => {:c => '6', :y => '543', :m => '2', :d => '1', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '-0543-02-01' => {:c => '-6', :y => '-543', :m => '2', :d => '1', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '-0543-02-01' => {:c => '-6', :y => '-543', :m => '2', :d => '1', :cq => '', :yq => '', :mq => '', :chron => :chronMax},
      '0543-02-01'  => {:c => '6', :y => '543', :m => '2', :d => '1', :cq => 'middle', :yq => 'beginning', :mq => 'beginning', :chron => :chronMin},
      '0543-02-01'  => {:c => '6', :y => '543', :m => '2', :d => '1', :cq => 'middle', :yq => 'beginning', :mq => 'beginning', :chron => :chronMax},
      '-0543-02-01' => {:c => '-6', :y => '-543', :m => '2', :d => '1', :cq => 'middle', :yq => 'beginning', :mq => 'beginning', :chron => :chronMin},
      '-0543-02-01' => {:c => '-6', :y => '-543', :m => '2', :d => '1', :cq => 'middle', :yq => 'beginning', :mq => 'beginning', :chron => :chronMax},
      '-0257-02-29' => {:c => '', :y => '-257', :m => '2', :d => '29', :cq => '', :yq => '', :mq => '', :chron => :chronMin},
      '-0257-02-29' => {:c => '', :y => '-257', :m => '2', :d => '29', :cq => '', :yq => '', :mq => '', :chron => :chronMax}
    })
  end

  protected

  def chronFunction testCases
    testCases.each_pair{|expected, testCase|
      result = HgvFuzzy.getChron(
        testCase[:c],
        testCase[:y],
        testCase[:m],
        testCase[:d],
        testCase[:cq],
        testCase[:yq],
        testCase[:mq],
        testCase[:chron]
      )
      assert_equal expected, result, 'HgvFuzzy.getChron(' + testCase.values.join(', ') + ')'
    }
  end

end

# jruby -I test test/unit/date_test.rb