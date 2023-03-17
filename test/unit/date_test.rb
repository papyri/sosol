require 'test_helper'

include HGVMetaIdentifierHelper

class DateTest < ActiveSupport::TestCase
  def setup; end

  def test_get_precision
    assert_nil            HGVDate.getPrecision(nil, nil, nil, nil),              'HGVDate.getPrecision'
    assert_equal :medium, HGVDate.getPrecision('ca', nil, nil, nil),             'HGVDate.getPrecision'
    assert_equal :lowlow, HGVDate.getPrecision(nil, 'beginningCirca', nil, nil), 'HGVDate.getPrecision'
    assert_equal :lowlow, HGVDate.getPrecision(nil, nil, 'middleCirca', nil),    'HGVDate.getPrecision'
    assert_equal :lowlow, HGVDate.getPrecision(nil, nil, nil, 'endCirca'),       'HGVDate.getPrecision'
    assert_equal :low,    HGVDate.getPrecision(nil, 'end', nil, nil),            'HGVDate.getPrecision'
    assert_equal :low,    HGVDate.getPrecision(nil, nil, 'middle', nil),         'HGVDate.getPrecision'
    assert_equal :low,    HGVDate.getPrecision(nil, nil, nil, 'beginning'),      'HGVDate.getPrecision'
  end

  def test_hgv_to_epidoc
    assert_equal(
      { value: 'Mitte III - Anfang (?) V',
        attributes: { id: nil, when: nil, notBefore: '0226', notAfter: '0425', certainty: nil, precision: nil }, children: { offset: [], precision: [{ value: nil, attributes: { match: '../@notBefore', degree: '0.3' }, children: {} }, { value: nil, attributes: { match: '../@notAfter', degree: '0.1' }, children: {} }], certainty: [] } },
      HGVDate.hgvToEpidoc({ c: 3, y: nil, m: nil, d: nil, cx: :middle, yx: nil, mx: nil, offset: nil,
                            precision: nil, ca: false, c2: 5, y2: nil, m2: nil, d2: nil, cx2: :beginningCirca, yx2: nil, mx2: nil, offset2: nil, precision2: nil, ca2: true, certainty: nil, unknown: nil, error: nil, empty: nil }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: '1884',
        attributes: { id: nil, when: '1884', notBefore: nil, notAfter: nil, certainty: nil, precision: nil }, children: { offset: [], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'vor 1884',
        attributes: { id: nil, when: nil, notBefore: nil, notAfter: '1884', certainty: nil, precision: nil }, children: { offset: [{ value: 'vor', attributes: { type: 'before', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', offset: 'before' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'nach 1884',
        attributes: { id: nil, when: nil, notBefore: '1884', notAfter: nil, certainty: nil, precision: nil }, children: { offset: [{ value: 'nach', attributes: { type: 'after', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', offset: 'after' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'Aug. 1884',
        attributes: { id: nil, when: '1884-08', notBefore: nil, notAfter: nil, certainty: nil, precision: nil }, children: { offset: [], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'vor Aug. 1884',
        attributes: { id: nil, when: nil, notBefore: nil, notAfter: '1884-08', certainty: nil, precision: nil }, children: { offset: [{ value: 'vor', attributes: { type: 'before', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8', offset: 'before' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'nach Aug. 1884',
        attributes: { id: nil, when: nil, notBefore: '1884-08', notAfter: nil, certainty: nil, precision: nil }, children: { offset: [{ value: 'nach', attributes: { type: 'after', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8', offset: 'after' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: '28. Aug. 1884',
        attributes: { id: nil, when: '1884-08-28', notBefore: nil, notAfter: nil, certainty: nil, precision: nil }, children: { offset: [], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8', d: '28' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'vor 28. Aug. 1884',
        attributes: { id: nil, when: nil, notBefore: nil, notAfter: '1884-08-28', certainty: nil, precision: nil }, children: { offset: [{ value: 'vor', attributes: { type: 'before', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8', d: '28', offset: 'before' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'nach 28. Aug. 1884',
        attributes: { id: nil, when: nil, notBefore: '1884-08-28', notAfter: nil, certainty: nil, precision: nil }, children: { offset: [{ value: 'nach', attributes: { type: 'after', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '1884', m: '8', d: '28', offset: 'after' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: '1884 v.Chr.',
        attributes: { id: nil, when: '-1884', notBefore: nil, notAfter: nil, certainty: nil, precision: nil }, children: { offset: [], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '-1884' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'vor Aug. 1884 v.Chr.',
        attributes: { id: nil, when: nil, notBefore: nil, notAfter: '-1884-08', certainty: nil, precision: nil }, children: { offset: [{ value: 'vor', attributes: { type: 'before', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '-1884', m: '8', offset: 'before' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'nach 28. Aug. 1884 v.Chr.',
        attributes: { id: nil, when: nil, notBefore: '-1884-08-28', notAfter: nil, certainty: nil, precision: nil }, children: { offset: [{ value: 'nach', attributes: { type: 'after', position: 1 }, children: {} }], precision: [], certainty: [] } },
      HGVDate.hgvToEpidoc({ y: '-1884', m: '8', d: '28', offset: 'after' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'vor (?) Aug. 1884 v.Chr.',
        attributes: { id: nil, when: nil, notBefore: nil, notAfter: '-1884-08', certainty: nil, precision: nil }, children: { offset: [{ value: 'vor (?)', attributes: { type: 'before', position: 1 }, children: {} }], precision: [], certainty: [{ value: nil, children: {}, attributes: { match: "../offset[@type='before']" } }] } },
      # {:value=>'', :attributes=>{:id=>nil, :when=>nil, :notBefore=>nil, :notAfter=>'-1884-08', :certainty=>nil, :precision=>nil}, :children=>{:offset=>[{:value => 'vor (?)', :attributes => {:type => 'before'}, :children => {}}], :precision=>[], :certainty=>[{:value => nil, :attribtues => {:match => "../offset[@type='before']"}, :children => {}}]}},
      HGVDate.hgvToEpidoc({ y: '-1884', m: '8', offset: 'beforeUncertain' }),
      'HGVDate.hgvToEpiDoc'
    )

    assert_equal(
      { value: 'nach (?) 28. Aug. 1884 v.Chr.',
        attributes: { id: nil, when: nil, notBefore: '-1884-08-28', notAfter: nil, certainty: nil, precision: nil }, children: { offset: [{ value: 'nach (?)', attributes: { type: 'after', position: 1 }, children: {} }], precision: [], certainty: [{ value: nil, children: {}, attributes: { match: "../offset[@type='after']" } }] } },
      HGVDate.hgvToEpidoc({ y: '-1884', m: '8', d: '28', offset: 'afterUncertain' }),
      'HGVDate.hgvToEpiDoc'
    )
  end

  def test_get_year_iso
    assert_equal '0401', HGVDate.getYearIso(5, nil, :chronMin)
    assert_equal '0500', HGVDate.getYearIso(5, nil, :chronMax)
    assert_equal '-0500', HGVDate.getYearIso(-5, nil, :chronMin)
    assert_equal '-0401', HGVDate.getYearIso(-5, nil, :chronMax)

    assert_equal '0401', HGVDate.getYearIso(5, :beginning, :chronMin)
    assert_equal '0425', HGVDate.getYearIso(5, :beginning, :chronMax)
    assert_equal '-0500', HGVDate.getYearIso(-5, :beginning, :chronMin)
    assert_equal '-0476', HGVDate.getYearIso(-5, :beginning, :chronMax)

    assert_equal '0426', HGVDate.getYearIso(5, :middleCirca, :chronMin)
    assert_equal '0475', HGVDate.getYearIso(5, :middleCirca, :chronMax)
    assert_equal '-0475', HGVDate.getYearIso(-5, :middleCirca, :chronMin)
    assert_equal '-0426', HGVDate.getYearIso(-5, :middleCirca, :chronMax)

    assert_equal '0476', HGVDate.getYearIso(5, :end, :chronMin)
    assert_equal '0500', HGVDate.getYearIso(5, :end, :chronMax)
    assert_equal '-0425', HGVDate.getYearIso(-5, :end, :chronMin)
    assert_equal '-0401', HGVDate.getYearIso(-5, :end, :chronMax)
  end

  def test_epidoc_to_hgv
    assert_equal({ c: 3, cx: :middle, ca: false, c2: 5, cx2: :beginningCirca, ca2: true, certainty: :low },
                 HGVDate.epidocToHGV({
                                       value: 'Mitte III - Anfang (?) V (?)',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '0226',
                                         notAfter: '0425',
                                         certainty: 'low',
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [
                                           { value: nil,
                                             attributes: { match: '../@notBefore' },
                                             children: {} },
                                           { value: nil,
                                             attributes: { match: '../@notAfter', degree: '0.1' },
                                             children: {} }
                                         ],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ c: 3, ca: true, c2: 5, ca2: true, precision: :ca, precision2: :ca },
                 HGVDate.epidocToHGV({
                                       value: 'ca. III - ca. V',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '0201',
                                         notAfter: '0500',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [
                                           { value: nil,
                                             attributes: { match: nil, degree: '0.1' },
                                             children: {} }
                                         ],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :beginning, ca: false, ca2: false, certainty: :year },
                 HGVDate.epidocToHGV({
                                       value: 'Anfang 1884 (Jahr unsicher)',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-01',
                                         notAfter: '1884-03',
                                         certainty: nil,
                                         precision: 'low'
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: [
                                           { value: nil, attributes: { match: '../year-from-date(@notBefore)' },
                                             children: {} },
                                           { value: nil, attributes: { match: '../year-from-date(@notAfter)' },
                                             children: {} }
                                         ]
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :summer, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Sommer 1884',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-05',
                                         notAfter: '1884-08',
                                         certainty: nil,
                                         precision: 'low'
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :end, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Ende 1884',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-10',
                                         notAfter: '1884-12',
                                         certainty: nil,
                                         precision: 'low'
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :end, y2: 1976, yx2: :beginning, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Ende 1884 - Anfang 1976',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-10',
                                         notAfter: '1976-03',
                                         certainty: nil,
                                         precision: 'low'
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :end, y2: 1976, m2: 3, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Ende 1884 - März 1976',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-10',
                                         notAfter: '1976-03',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [{ value: nil, attributes: { match: '../@notBefore' },
                                                       children: {} }],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :end, y2: 1976, m2: 3, d2: 5, ca: false, ca2: false, certainty: :month_year },
                 HGVDate.epidocToHGV({
                                       value: 'Ende 1884 - 5. März 1976 (Jahr und Monat unsicher)',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-10',
                                         notAfter: '1976-03-05',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [{ value: nil, attributes: { match: '../@notBefore' },
                                                       children: {} }],
                                         certainty: [
                                           { value: nil, attributes: { match: '../year-from-date(@notAfter)' },
                                             children: {} },
                                           { value: nil, attributes: { match: '../month-from-date(@notAfter)' },
                                             children: {} }
                                         ]
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, y2: 1976, yx2: :beginning, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: '1884 - Anfang 1976',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884',
                                         notAfter: '1976-03',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [{ value: nil, attributes: { match: '../@notAfter' },
                                                       children: {} }],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, y2: 1976, m2: 3, mx2: :beginning, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: '1884 - Anfang März 1976',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884',
                                         notAfter: '1976-03-10',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [{ value: nil, attributes: { match: '../@notAfter' },
                                                       children: {} }],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, yx: :end, y2: 1976, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Ende 1884 - 1976',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: nil,
                                         notBefore: '1884-10',
                                         notAfter: '1976',
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [
                                           { value: nil,
                                             attributes: { match: '../@notBefore' },
                                             children: {} }
                                         ],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, m: 8, d: 28, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: '28. Aug. 1884',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: '1884-08-28',
                                         notBefore: nil,
                                         notAfter: nil,
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, m: 8, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: 'Aug. 1884',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: '1884-08',
                                         notBefore: nil,
                                         notAfter: nil,
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')

    assert_equal({ y: 1884, ca: false, ca2: false },
                 HGVDate.epidocToHGV({
                                       value: '1884',
                                       attributes: {
                                         textDateId: 'dateAlternativeX',
                                         when: '1884',
                                         notBefore: nil,
                                         notAfter: nil,
                                         certainty: nil,
                                         precision: nil
                                       },
                                       children: {
                                         offset: [],
                                         precision: [],
                                         certainty: []
                                       }
                                     }).delete_if { |_k, v| v.nil? },
                 'HGVDate.epidocToHGV()')
  end

  def test_get_century
    assert_equal 1, HGVDate.getCentury(1), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(2), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(3), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(49), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(50), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(51), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(98), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(99), 'HGVDate.getCentury()'
    assert_equal 1, HGVDate.getCentury(100), 'HGVDate.getCentury()'

    assert_equal 2, HGVDate.getCentury(101), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(102), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(103), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(149), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(150), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(151), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(198), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(199), 'HGVDate.getCentury()'
    assert_equal 2, HGVDate.getCentury(200), 'HGVDate.getCentury()'

    assert_equal 20, HGVDate.getCentury(1901), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1902), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1903), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1949), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1950), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1951), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1998), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(1999), 'HGVDate.getCentury()'
    assert_equal 20, HGVDate.getCentury(2000), 'HGVDate.getCentury()'

    assert_equal(-1, HGVDate.getCentury(-1), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-2), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-3), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-49), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-50), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-51), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-98), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-99), 'HGVDate.getCentury()')
    assert_equal(-1, HGVDate.getCentury(-100), 'HGVDate.getCentury()')

    assert_equal(-2, HGVDate.getCentury(-101), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-102), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-103), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-149), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-150), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-151), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-198), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-199), 'HGVDate.getCentury()')
    assert_equal(-2, HGVDate.getCentury(-200), 'HGVDate.getCentury()')

    assert_equal(-20, HGVDate.getCentury(-1901), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1902), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1903), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1949), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1950), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1951), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1998), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-1999), 'HGVDate.getCentury()')
    assert_equal(-20, HGVDate.getCentury(-2000), 'HGVDate.getCentury()')
  end

  def test_get_century_qualifier
    assert_equal :middle, HGVDate.getCenturyQualifier(126, 175), 'HGVDate.getCenturyQualifier()'
    assert_equal %i[middle middle], HGVDate.getCenturyQualifier(126, 275), 'HGVDate.getCenturyQualifier()'
  end

  def test_format_date
    assert_equal '', HGVFormat.formatDate({}), 'HGVFormat.formatDate'
    assert_equal 'V', HGVFormat.formatDate({ c: 5 }), 'HGVFormat.formatDate'
    assert_equal 'V', HGVFormat.formatDate({ c: '5' }), 'HGVFormat.formatDate'
    assert_equal 'Anfang V', HGVFormat.formatDate({ c: 5, cx: :beginning }), 'HGVFormat.formatDate'
    assert_equal 'Anfang V', HGVFormat.formatDate({ c: 5, cx: 'beginning' }), 'HGVFormat.formatDate'
    assert_equal '1976 - 1984', HGVFormat.formatDate({ y: 1976, y2: 1984 }), 'HGVFormat.formatDate'
    assert_equal '1976 - 1984', HGVFormat.formatDate({ y: '1976', y2: '1984' }), 'HGVFormat.formatDate'
    assert_equal 'Ende 1976 - Anfang 1984',
                 HGVFormat.formatDate({ y: '1976', y2: '1984', yx: :end, yx2: :beginning }), 'HGVFormat.formatDate'
    assert_equal 'V - III v.Chr.', HGVFormat.formatDate({ c: -5, c2: -3 }), 'HGVFormat.formatDate'
    assert_equal 'vor V', HGVFormat.formatDate({ c: 5, offset: :before }), 'HGVFormat.formatDate'
    assert_equal 'vor V', HGVFormat.formatDate({ c: 5, offset: 'before' }), 'HGVFormat.formatDate'
    assert_equal 'ca. vor Ende V', HGVFormat.formatDate({ c: 5, offset: :before, precision: :ca, cx: :end }),
                 'HGVFormat.formatDate'
    assert_equal 'ca. vor Ende V',
                 HGVFormat.formatDate({ c: 5, offset: :before, precision: 'ca', cx: :end }), 'HGVFormat.formatDate'
    assert_equal 'vor Ende V (?)',
                 HGVFormat.formatDate({ c: 5, offset: :before, certainty: :low, cx: :end }), 'HGVFormat.formatDate'
    assert_equal 'vor Ende V (?)',
                 HGVFormat.formatDate({ c: 5, offset: :before, certainty: 'low', cx: :end }), 'HGVFormat.formatDate'
    assert_equal 'nach 1976 - vor 1984',
                 HGVFormat.formatDate({ y: 1976, y2: 1984, offset: :after, offset2: :before }), 'HGVFormat.formatDate'
    assert_equal 'V - vor III v.Chr.', HGVFormat.formatDate({ c: -5, c2: -3, offset2: :before }),
                 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before }), 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984 (Jahr unsicher)',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before, certainty: :year }), 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984 (Jahr unsicher)',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before, certainty: 'year' }), 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984 (Jahr und Monat unsicher)',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before, certainty: :month_year }), 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984 (Monat und Tag unsicher)',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before, certainty: :day_month }), 'HGVFormat.formatDate'
    assert_equal 'nach 6. Juli 1976 - vor 28. Aug. 1984 (Jahr, Monat und Tag unsicher)',
                 HGVFormat.formatDate({ y: 1976, m: 7, d: 6, offset: :after, y2: 1984, m2: 8, d2: 28, offset2: :before, certainty: :day_month_year }), 'HGVFormat.formatDate'
    assert_equal 'Anfang Jan. 1976', HGVFormat.formatDate({ y: 1976, m: 1, mx: :beginning }),
                 'HGVFormat.formatDate'
    assert_equal '1. Hälfte 1976', HGVFormat.formatDate({ y: 1976, yx: :firstHalf }), 'HGVFormat.formatDate'
    assert_equal 'Mitte - Ende V', HGVFormat.formatDate({ c: 5, cx: :middleToEnd }), 'HGVFormat.formatDate'
  end

  def test_format_date_part
    assert_equal 'Jan.',  HGVFormat.formatDatePart(nil, nil,  1), 'HGVFormat.formatDate'
    assert_equal 'Febr.', HGVFormat.formatDatePart(nil, nil,  2), 'HGVFormat.formatDate'
    assert_equal 'März',  HGVFormat.formatDatePart(nil, nil,  3), 'HGVFormat.formatDate'
    assert_equal 'Apr.',  HGVFormat.formatDatePart(nil, nil,  4), 'HGVFormat.formatDate'
    assert_equal 'Mai',   HGVFormat.formatDatePart(nil, nil,  5), 'HGVFormat.formatDate'
    assert_equal 'Juni',  HGVFormat.formatDatePart(nil, nil,  6), 'HGVFormat.formatDate'
    assert_equal 'Juli',  HGVFormat.formatDatePart(nil, nil,  7), 'HGVFormat.formatDate'
    assert_equal 'Aug.',  HGVFormat.formatDatePart(nil, nil,  8), 'HGVFormat.formatDate'
    assert_equal 'Sept.', HGVFormat.formatDatePart(nil, nil,  9), 'HGVFormat.formatDate'
    assert_equal 'Okt.',  HGVFormat.formatDatePart(nil, nil, 10), 'HGVFormat.formatDate'
    assert_equal 'Nov.',  HGVFormat.formatDatePart(nil, nil, 11), 'HGVFormat.formatDate'
    assert_equal 'Dez.',  HGVFormat.formatDatePart(nil, nil, 12), 'HGVFormat.formatDate'

    assert_equal '1. Jan.',   HGVFormat.formatDatePart(nil, nil,  1,  1), 'HGVFormat.formatDate'
    assert_equal '2. Febr.',  HGVFormat.formatDatePart(nil, nil,  2,  2), 'HGVFormat.formatDate'
    assert_equal '3. März',   HGVFormat.formatDatePart(nil, nil,  3,  3), 'HGVFormat.formatDate'
    assert_equal '4. Apr.',   HGVFormat.formatDatePart(nil, nil,  4,  4), 'HGVFormat.formatDate'
    assert_equal '5. Mai',    HGVFormat.formatDatePart(nil, nil,  5,  5), 'HGVFormat.formatDate'
    assert_equal '6. Juni',   HGVFormat.formatDatePart(nil, nil,  6,  6), 'HGVFormat.formatDate'
    assert_equal '7. Juli',   HGVFormat.formatDatePart(nil, nil,  7,  7), 'HGVFormat.formatDate'
    assert_equal '8. Aug.',   HGVFormat.formatDatePart(nil, nil,  8,  8), 'HGVFormat.formatDate'
    assert_equal '9. Sept.',  HGVFormat.formatDatePart(nil, nil,  9,  9), 'HGVFormat.formatDate'
    assert_equal '10. Okt.',  HGVFormat.formatDatePart(nil, nil, 10, 10), 'HGVFormat.formatDate'
    assert_equal '11. Nov.',  HGVFormat.formatDatePart(nil, nil, 11, 11), 'HGVFormat.formatDate'
    assert_equal '12. Dez.',  HGVFormat.formatDatePart(nil, nil, 12, 12), 'HGVFormat.formatDate'

    assert_equal '1. Jan. 1992',  HGVFormat.formatDatePart(nil, 1992,  1,  1), 'HGVFormat.formatDate'
    assert_equal '2. Febr. 1834', HGVFormat.formatDatePart(nil, 1834,  2,  2), 'HGVFormat.formatDate'
    assert_equal '3. März 2010',  HGVFormat.formatDatePart(nil, 2010,  3,  3), 'HGVFormat.formatDate'
    assert_equal '4. Apr. 111',   HGVFormat.formatDatePart(nil,  111,  4,  4), 'HGVFormat.formatDate'
    assert_equal '5. Mai 434',    HGVFormat.formatDatePart(nil,  434,  5,  5), 'HGVFormat.formatDate'
    assert_equal '6. Juni 123',   HGVFormat.formatDatePart(nil,  123,  6,  6), 'HGVFormat.formatDate'
    assert_equal '7. Juli 23',    HGVFormat.formatDatePart(nil,   23,  7,  7), 'HGVFormat.formatDate'
    assert_equal '8. Aug. 45',    HGVFormat.formatDatePart(nil,   45,  8,  8), 'HGVFormat.formatDate'
    assert_equal '9. Sept. 34',   HGVFormat.formatDatePart(nil,   34,  9,  9), 'HGVFormat.formatDate'
    assert_equal '10. Okt. 2',    HGVFormat.formatDatePart(nil,    2, 10, 10), 'HGVFormat.formatDate'
    assert_equal '11. Nov. 5',    HGVFormat.formatDatePart(nil,    5, 11, 11), 'HGVFormat.formatDate'
    assert_equal '12. Dez. 8',    HGVFormat.formatDatePart(nil,    8, 12, 12), 'HGVFormat.formatDate'

    assert_equal '1. Jan. 1992 v.Chr.',  HGVFormat.formatDatePart(nil, -1992,  1,  1), 'HGVFormat.formatDate'
    assert_equal '2. Febr. 1834 v.Chr.', HGVFormat.formatDatePart(nil, -1834,  2,  2), 'HGVFormat.formatDate'
    assert_equal '3. März 2010 v.Chr.',  HGVFormat.formatDatePart(nil, -2010,  3,  3), 'HGVFormat.formatDate'
    assert_equal '4. Apr. 111 v.Chr.',   HGVFormat.formatDatePart(nil,  -111,  4,  4), 'HGVFormat.formatDate'
    assert_equal '5. Mai 434 v.Chr.',    HGVFormat.formatDatePart(nil,  -434,  5,  5), 'HGVFormat.formatDate'
    assert_equal '6. Juni 123 v.Chr.',   HGVFormat.formatDatePart(nil,  -123,  6,  6), 'HGVFormat.formatDate'
    assert_equal '7. Juli 23 v.Chr.',    HGVFormat.formatDatePart(nil,   -23,  7,  7), 'HGVFormat.formatDate'
    assert_equal '8. Aug. 45 v.Chr.',    HGVFormat.formatDatePart(nil,   -45,  8,  8), 'HGVFormat.formatDate'
    assert_equal '9. Sept. 34 v.Chr.',   HGVFormat.formatDatePart(nil,   -34,  9,  9), 'HGVFormat.formatDate'
    assert_equal '10. Okt. 2 v.Chr.',    HGVFormat.formatDatePart(nil,    -2, 10, 10), 'HGVFormat.formatDate'
    assert_equal '11. Nov. 5 v.Chr.',    HGVFormat.formatDatePart(nil,    -5, 11, 11), 'HGVFormat.formatDate'
    assert_equal '12. Dez. 8 v.Chr.',    HGVFormat.formatDatePart(nil,    -8, 12, 12), 'HGVFormat.formatDate'

    assert_equal 'Jan. 1',           HGVFormat.formatDatePart(nil,     1,  1), 'HGVFormat.formatDate'
    assert_equal 'Febr. 1 v.Chr.',   HGVFormat.formatDatePart(nil,    -1,  2), 'HGVFormat.formatDate'
    assert_equal 'März 23',          HGVFormat.formatDatePart(nil,    23,  3), 'HGVFormat.formatDate'
    assert_equal 'Apr. 23 v.Chr.',   HGVFormat.formatDatePart(nil,   -23,  4), 'HGVFormat.formatDate'
    assert_equal 'Mai 345',          HGVFormat.formatDatePart(nil,   345,  5), 'HGVFormat.formatDate'
    assert_equal 'Juni 345 v.Chr.',  HGVFormat.formatDatePart(nil,  -345,  6), 'HGVFormat.formatDate'
    assert_equal 'Juli 1921',        HGVFormat.formatDatePart(nil,  1921,  7), 'HGVFormat.formatDate'
    assert_equal 'Aug. 1921 v.Chr.', HGVFormat.formatDatePart(nil, -1921,  8), 'HGVFormat.formatDate'
    assert_equal 'Sept. 4',          HGVFormat.formatDatePart(nil, 4, 9), 'HGVFormat.formatDate'
    assert_equal 'Okt. 45 v.Chr.',   HGVFormat.formatDatePart(nil,   -45, 10), 'HGVFormat.formatDate'
    assert_equal 'Nov. 678',         HGVFormat.formatDatePart(nil,   678, 11), 'HGVFormat.formatDate'
    assert_equal 'Dez. 1918 v.Chr.', HGVFormat.formatDatePart(nil, -1918, 12), 'HGVFormat.formatDate'

    assert_equal 'I',     HGVFormat.formatDatePart(1), 'HGVFormat.formatDate'
    assert_equal 'II',    HGVFormat.formatDatePart(2), 'HGVFormat.formatDate'
    assert_equal 'III',   HGVFormat.formatDatePart(3), 'HGVFormat.formatDate'
    assert_equal 'IV',    HGVFormat.formatDatePart(4), 'HGVFormat.formatDate'
    assert_equal 'V',     HGVFormat.formatDatePart(5), 'HGVFormat.formatDate'
    assert_equal 'VI',    HGVFormat.formatDatePart(6), 'HGVFormat.formatDate'
    assert_equal 'VII',   HGVFormat.formatDatePart(7), 'HGVFormat.formatDate'
    assert_equal 'VIII',  HGVFormat.formatDatePart(8), 'HGVFormat.formatDate'
    assert_equal 'IX',    HGVFormat.formatDatePart(9), 'HGVFormat.formatDate'
    assert_equal 'X',     HGVFormat.formatDatePart(10), 'HGVFormat.formatDate'
    assert_equal 'XI',    HGVFormat.formatDatePart(11), 'HGVFormat.formatDate'
    assert_equal 'XII',   HGVFormat.formatDatePart(12), 'HGVFormat.formatDate'
    assert_equal 'XIII',  HGVFormat.formatDatePart(13), 'HGVFormat.formatDate'
    assert_equal 'XIV',   HGVFormat.formatDatePart(14), 'HGVFormat.formatDate'
    assert_equal 'XV',    HGVFormat.formatDatePart(15), 'HGVFormat.formatDate'
    assert_equal 'XVI',   HGVFormat.formatDatePart(16), 'HGVFormat.formatDate'
    assert_equal 'XVII',  HGVFormat.formatDatePart(17), 'HGVFormat.formatDate'
    assert_equal 'XVIII', HGVFormat.formatDatePart(18), 'HGVFormat.formatDate'
    assert_equal 'XIX',   HGVFormat.formatDatePart(19), 'HGVFormat.formatDate'
    assert_equal 'XX',    HGVFormat.formatDatePart(20), 'HGVFormat.formatDate'

    assert_equal 'XLI v.Chr.',    HGVFormat.formatDatePart(-41), 'HGVFormat.formatDate'
    assert_equal 'XLII v.Chr.',   HGVFormat.formatDatePart(-42), 'HGVFormat.formatDate'
    assert_equal 'XLIII v.Chr.',  HGVFormat.formatDatePart(-43), 'HGVFormat.formatDate'
    assert_equal 'XLIV v.Chr.',   HGVFormat.formatDatePart(-44), 'HGVFormat.formatDate'
    assert_equal 'XLV v.Chr.',    HGVFormat.formatDatePart(-45), 'HGVFormat.formatDate'
    assert_equal 'XLVI v.Chr.',   HGVFormat.formatDatePart(-46), 'HGVFormat.formatDate'
    assert_equal 'XLVII v.Chr.',  HGVFormat.formatDatePart(-47), 'HGVFormat.formatDate'
    assert_equal 'XLVIII v.Chr.', HGVFormat.formatDatePart(-48), 'HGVFormat.formatDate'
    assert_equal 'XLIX v.Chr.',   HGVFormat.formatDatePart(-49), 'HGVFormat.formatDate'
    assert_equal 'L v.Chr.',      HGVFormat.formatDatePart(-50), 'HGVFormat.formatDate'

    assert_equal 'Anfang Jan. 1976',  HGVFormat.formatDatePart(nil, 1976,  1, nil, nil, nil, 'beginning'),
                 'HGVFormat.formatDate'
    assert_equal 'Mitte Juli 1976',   HGVFormat.formatDatePart(nil, 1976,  7, nil, nil, nil, 'middle'),
                 'HGVFormat.formatDate'
    assert_equal 'Ende Dez. 1976',    HGVFormat.formatDatePart(nil, 1976, 12, nil, nil, nil, 'end'),
                 'HGVFormat.formatDate'
    assert_equal 'Anfang Febr. 1984', HGVFormat.formatDatePart(nil, 1984,  2, nil, nil, nil, :beginning),
                 'HGVFormat.formatDate'
    assert_equal 'Mitte Aug. 1984',   HGVFormat.formatDatePart(nil, 1984,  8, nil, nil, nil, :middle),
                 'HGVFormat.formatDate'
    assert_equal 'Ende Nov. 1984',    HGVFormat.formatDatePart(nil, 1984, 11, nil, nil, nil, :end),
                 'HGVFormat.formatDate'

    assert_equal 'Anfang XXXI v.Chr.',     HGVFormat.formatDatePart(-31, nil, nil, nil, :beginning),
                 'HGVFormat.formatDate'
    assert_equal 'Mitte XXXII v.Chr.',     HGVFormat.formatDatePart(-32, nil, nil, nil, :middle), 'HGVFormat.formatDate'
    assert_equal 'Ende XXXIII v.Chr.',     HGVFormat.formatDatePart(-33, nil, nil, nil, :end), 'HGVFormat.formatDate'
    assert_equal '1. Hälfte XXXIV v.Chr.', HGVFormat.formatDatePart(-34, nil, nil, nil, :firstHalf),
                 'HGVFormat.formatDate'
    assert_equal '2. Hälfte XXXV v.Chr.',  HGVFormat.formatDatePart(-35, nil, nil, nil, :secondHalf),
                 'HGVFormat.formatDate'
    assert_equal '1. Hälfte - Mitte XXXVI v.Chr.',
                 HGVFormat.formatDatePart(-36, nil, nil, nil, :firstHalfToMiddle), 'HGVFormat.formatDate'
    assert_equal 'Mitte - 2. Hälfte XXXVII v.Chr.',
                 HGVFormat.formatDatePart(-37, nil, nil, nil, :middleToSecondHalf), 'HGVFormat.formatDate'
    assert_equal 'Anfang XXXVIII v.Chr.',  HGVFormat.formatDatePart(-38, nil, nil, nil, 'beginning'),
                 'HGVFormat.formatDate'
    assert_equal 'Mitte XXXIX v.Chr.',     HGVFormat.formatDatePart(-39, nil, nil, nil, 'middle'),
                 'HGVFormat.formatDate'
    assert_equal 'Ende XL v.Chr.',         HGVFormat.formatDatePart(-40, nil, nil, nil, 'end'), 'HGVFormat.formatDate'

    assert_equal 'Anfang 1976 v.Chr.',    HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :beginning),
                 'HGVFormat.formatDate'
    assert_equal 'Mitte 1976 v.Chr.',     HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :middle),
                 'HGVFormat.formatDate'
    assert_equal 'Ende 1976 v.Chr.',      HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :end),
                 'HGVFormat.formatDate'
    assert_equal '1. Hälfte 1976 v.Chr.', HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :firstHalf),
                 'HGVFormat.formatDate'
    assert_equal '2. Hälfte 1976 v.Chr.', HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :secondHalf),
                 'HGVFormat.formatDate'
    assert_equal '1. Hälfte - Mitte 1976 v.Chr.',
                 HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :firstHalfToMiddle), 'HGVFormat.formatDate'
    assert_equal 'Mitte - 2. Hälfte 1976 v.Chr.',
                 HGVFormat.formatDatePart(nil, -1976, nil, nil, nil, :middleToSecondHalf), 'HGVFormat.formatDate'
  end

  def test_get_chron_simple
    chronFunctionSimple({
                          '-0200' => { c: '-2', y: '', m: '', d: '', cq: '', yq: '', mq: '',
                                       chron: :chronMin },
                          '-0001' => { c: '-1', y: '', m: '', d: '', cq: '', yq: '', mq: '',
                                       chron: :chronMax },
                          '0201' => { c: '3',  y: '', m: '', d: '', cq: '', yq: '', mq: '',
                                      chron: :chronMin },
                          '0400' => { c: '4',  y: '', m: '', d: '', cq: '', yq: '', mq: '',
                                      chron: :chronMax },

                          '-0175' => { c: '-2', y: '', m: '', d: '', cq: 'middle', yq: '', mq: '',
                                       chron: :chronMin },
                          '-0076' => { c: '-1', y: '', m: '', d: '', cq: 'beginning', yq: '', mq: '',
                                       chron: :chronMax },
                          '0276' => { c: '3',  y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                      chron: :chronMin },
                          '0350' => { c: '4',  y: '', m: '', d: '', cq: 'first_half', yq: '', mq: '',
                                      chron: :chronMax },
                          '' => { c: '4', y: '', m: '', d: '', cq: '', yq: '', mq: '',
                                  chron: :chron },

                          '-1976' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: '', mq: '',
                                       chron: :chron },
                          '1976' => { c: '', y: '1976', m: '', d: '', cq: '', yq: '', mq: '',
                                      chron: :chron },
                          '-1976-07' => { c: '', y: '-1976', m: 7, d: '', cq: '', yq: '', mq: '',
                                          chron: :chron },
                          '1976-08' => { c: '', y: '1976', m: 8, d: '', cq: '', yq: '', mq: '',
                                         chron: :chron },
                          '-1976-07-06' => { c: '', y: '-1976', m: 7, d: '6', cq: '', yq: '', mq: '',
                                             chron: :chron },
                          '1976-08-07' => { c: '', y: '1976', m: 8, d: '7', cq: '', yq: '',
                                            mq: '', chron: :chron }
                        })
  end

  def test_century_qualifier
    chronFunction({
                    '-0476-12-31' => { c: '-5', y: '', m: '', d: '', cq: 'beginning', yq: '', mq: '',
                                       chron: :chronMax },
                    '-0076-12-31' => { c: '-1', y: '', m: '', d: '', cq: 'beginning', yq: '', mq: '',
                                       chron: :chronMax },
                    '0025-12-31' => { c: '1',  y: '', m: '', d: '', cq: 'beginning', yq: '', mq: '',
                                      chron: :chronMax },
                    '0425-12-31' => { c: '5',  y: '', m: '', d: '', cq: 'beginning', yq: '', mq: '',
                                      chron: :chronMax },

                    '-0500-01-01' => { c: '-5', y: '', m: '', d: '', cq: 'first_half', yq: '', mq: '',
                                       chron: :chronMin },
                    '-0100-01-01' => { c: '-1', y: '', m: '', d: '', cq: 'first_half', yq: '', mq: '',
                                       chron: :chronMin },
                    '0001-01-01' => { c: '1',  y: '', m: '', d: '', cq: 'first_half', yq: '', mq: '',
                                      chron: :chronMin },
                    '0401-01-01' => { c: '5',  y: '', m: '', d: '', cq: 'first_half', yq: '', mq: '',
                                      chron: :chronMin },

                    '-0451-12-31' => { c: '-5', y: '', m: '', d: '', cq: 'first_half_to_middle', yq: '', mq: '',
                                       chron: :chronMax },
                    '-0051-12-31' => { c: '-1', y: '', m: '', d: '', cq: 'first_half_to_middle', yq: '', mq: '',
                                       chron: :chronMax },
                    '0050-12-31' => { c: '1',  y: '', m: '', d: '', cq: 'first_half_to_middle', yq: '', mq: '',
                                      chron: :chronMax },
                    '0450-12-31' => { c: '5',  y: '', m: '', d: '', cq: 'first_half_to_middle', yq: '', mq: '',
                                      chron: :chronMax },

                    '-0475-01-01' => { c: '-5', y: '', m: '', d: '', cq: 'middle', yq: '', mq: '',
                                       chron: :chronMin },
                    '-0075-01-01' => { c: '-1', y: '', m: '', d: '', cq: 'middle', yq: '', mq: '',
                                       chron: :chronMin },
                    '0026-01-01' => { c: '1',  y: '', m: '', d: '', cq: 'middle', yq: '', mq: '',
                                      chron: :chronMin },
                    '0426-01-01' => { c: '5',  y: '', m: '', d: '', cq: 'middle', yq: '', mq: '',
                                      chron: :chronMin },

                    '-0426-12-31' => { c: '-5', y: '', m: '', d: '', cq: 'middle_to_second_half', yq: '', mq: '',
                                       chron: :chronMax },
                    '-0026-12-31' => { c: '-1', y: '', m: '', d: '', cq: 'middle_to_second_half', yq: '', mq: '',
                                       chron: :chronMax },
                    '0075-12-31' => { c: '1',  y: '', m: '', d: '', cq: 'middle_to_second_half', yq: '', mq: '',
                                      chron: :chronMax },
                    '0475-12-31' => { c: '5',  y: '', m: '', d: '', cq: 'middle_to_second_half', yq: '', mq: '',
                                      chron: :chronMax },

                    '-0450-01-01' => { c: '-5', y: '', m: '', d: '', cq: 'second_half', yq: '', mq: '',
                                       chron: :chronMin },
                    '-0050-01-01' => { c: '-1', y: '', m: '', d: '', cq: 'second_half', yq: '', mq: '',
                                       chron: :chronMin },
                    '0051-01-01' => { c: '1',  y: '', m: '', d: '', cq: 'second_half', yq: '', mq: '',
                                      chron: :chronMin },
                    '0451-01-01' => { c: '5',  y: '', m: '', d: '', cq: 'second_half', yq: '', mq: '',
                                      chron: :chronMin },

                    '-0425-01-01' => { c: '-5', y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                       chron: :chronMin },
                    '-0025-01-01' => { c: '-1', y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                       chron: :chronMin },
                    '0076-01-01' => { c: '1',  y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                      chron: :chronMin },
                    '0476-01-01' => { c: '5',  y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                      chron: :chronMin },

                    '-0401-12-31' => { c: '-5', y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                       chron: :chronMax },
                    '-0001-12-31' => { c: '-1', y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                       chron: :chronMax },
                    '0100-12-31' => { c: '1',  y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                      chron: :chronMax },
                    '0500-12-31' => { c: '5',  y: '', m: '', d: '', cq: 'end', yq: '', mq: '',
                                      chron: :chronMax }
                  })
  end

  def test_year_qualifier
    chronFunction({
                    '0001-03-31' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'beginning', mq: '',
                                      chron: :chronMax },
                    '1976-03-31' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'beginning', mq: '',
                                      chron: :chronMax },
                    '-0001-03-31' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'beginning', mq: '',
                                       chron: :chronMax },
                    '-1976-03-31' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'beginning', mq: '',
                                       chron: :chronMax },

                    '0001-01-01' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'first_half', mq: '',
                                      chron: :chronMin },
                    '1976-01-01' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'first_half', mq: '',
                                      chron: :chronMin },
                    '-0001-01-01' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'first_half', mq: '',
                                       chron: :chronMin },
                    '-1976-01-01' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'first_half', mq: '',
                                       chron: :chronMin },

                    '0001-06-30' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'first_half_to_middle',
                                      mq: '', chron: :chronMax },
                    '1976-06-30' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'first_half_to_middle',
                                      mq: '', chron: :chronMax },
                    '-1976-06-30' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'first_half_to_middle',
                                       mq: '', chron: :chronMax },

                    '0001-04-01' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'middle', mq: '',
                                      chron: :chronMin },
                    '1976-04-01' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'middle', mq: '',
                                      chron: :chronMin },
                    '-0001-04-01' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'middle', mq: '',
                                       chron: :chronMin },
                    '-1976-04-01' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'middle', mq: '',
                                       chron: :chronMin },

                    '0001-09-30' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'middle_to_second_half',
                                      mq: '', chron: :chronMax },
                    '1976-09-30' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'middle_to_second_half',
                                      mq: '', chron: :chronMax },
                    '-0001-09-30' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'middle_to_second_half',
                                       mq: '', chron: :chronMax },
                    '-1976-09-30' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'middle_to_second_half',
                                       mq: '', chron: :chronMax },

                    '0001-07-01' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'second_half', mq: '',
                                      chron: :chronMin },
                    '1976-07-01' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'second_half', mq: '',
                                      chron: :chronMin },
                    '-0001-07-01' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'second_half', mq: '',
                                       chron: :chronMin },
                    '-1976-07-01' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'second_half', mq: '',
                                       chron: :chronMin },

                    '0001-10-01' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'end', mq: '',
                                      chron: :chronMin },
                    '1976-10-01' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'end', mq: '',
                                      chron: :chronMin },
                    '-0001-10-01' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'end', mq: '',
                                       chron: :chronMin },
                    '-1976-10-01' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'end', mq: '',
                                       chron: :chronMin },

                    '0001-12-31' => { c: '', y: '1',     m: '', d: '', cq: '', yq: 'end', mq: '',
                                      chron: :chronMax },
                    '1976-12-31' => { c: '', y: '1976',  m: '', d: '', cq: '', yq: 'end', mq: '',
                                      chron: :chronMax },
                    '-0001-12-31' => { c: '', y: '-1',    m: '', d: '', cq: '', yq: 'end', mq: '',
                                       chron: :chronMax },
                    '-1976-12-31' => { c: '', y: '-1976', m: '', d: '', cq: '', yq: 'end', mq: '',
                                       chron: :chronMax }
                  })
  end

  def test_month_qualifier
    chronFunction({
                    '-1976-01-01' => { c: '', y: '-1976', m: '1', d: '', cq: '', yq: '', mq: 'beginning',
                                       chron: :chronMin },
                    '-0001-06-01' => { c: '', y: '-1',    m: '6', d: '', cq: '', yq: '', mq: 'beginning',
                                       chron: :chronMin },
                    '0001-07-01' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'beginning',
                                      chron: :chronMin },
                    '1976-12-01' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'beginning',
                                      chron: :chronMin },
                    '-1976-01-11' => { c: '', y: '-1976', m: '1',  d: '', cq: '', yq: '', mq: 'middle',
                                       chron: :chronMin },
                    '-0001-06-11' => { c: '', y: '-1',    m: '6',  d: '', cq: '', yq: '', mq: 'middle',
                                       chron: :chronMin },
                    '0001-07-11' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'middle',
                                      chron: :chronMin },
                    '1976-12-11' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'middle',
                                      chron: :chronMin },
                    '-1976-01-21' => { c: '', y: '-1976', m: '1',  d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMin },
                    '-0001-06-21' => { c: '', y: '-1',    m: '6',  d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMin },
                    '0001-07-21' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMin },
                    '1976-12-21' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMin },
                    '-1976-01-10' => { c: '', y: '-1976', m: '1',  d: '', cq: '', yq: '', mq: 'beginning',
                                       chron: :chronMax },
                    '-0001-06-10' => { c: '', y: '-1',    m: '6',  d: '', cq: '', yq: '', mq: 'beginning',
                                       chron: :chronMax },
                    '0001-07-10' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'beginning',
                                      chron: :chronMax },
                    '1976-12-10' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'beginning',
                                      chron: :chronMax },
                    '-1976-01-20' => { c: '', y: '-1976', m: '1',  d: '', cq: '', yq: '', mq: 'middle',
                                       chron: :chronMax },
                    '-0001-06-20' => { c: '', y: '-1',    m: '6',  d: '', cq: '', yq: '', mq: 'middle',
                                       chron: :chronMax },
                    '0001-07-20' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'middle',
                                      chron: :chronMax },
                    '1976-12-20' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'middle',
                                      chron: :chronMax },
                    '-1976-01-31' => { c: '', y: '-1976', m: '1',  d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-0001-06-30' => { c: '', y: '-1',    m: '6',  d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '0001-07-31' => { c: '', y: '1',     m: '7',  d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1976-12-31' => { c: '', y: '1976',  m: '12', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax }
                  })
  end

  def test_leap_year
    chronFunction({
                    '1600-02-29' => { c: '', y: '1600', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1700-02-28' => { c: '', y: '1700', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1800-02-28' => { c: '', y: '1800', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1900-02-28' => { c: '', y: '1900', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '2000-02-29' => { c: '', y: '2000', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1976-02-29' => { c: '', y: '1976', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },
                    '1977-02-28' => { c: '', y: '1977', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                      chron: :chronMax },

                    '-1600-02-29' => { c: '', y: '-1600', m: '2', d: '', cq: '', yq: '', mq: 'end', chron: :chronMax }, # is this really what we would exspect?
                    '-1700-02-28' => { c: '', y: '-1700', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-1800-02-28' => { c: '', y: '-1800', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-1900-02-28' => { c: '', y: '-1900', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-2000-02-29' => { c: '', y: '-2000', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-1976-02-29' => { c: '', y: '-1976', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax },
                    '-1977-02-28' => { c: '', y: '-1977', m: '2', d: '', cq: '', yq: '', mq: 'end',
                                       chron: :chronMax }
                  })
  end

  def test_miscellaneous
    chronFunction({
                    '0543-02-01' => { c: '6', y: '543', m: '2', d: '1', cq: 'middle', yq: 'beginning',
                                      mq: 'beginning', chron: :chronMax },
                    '-0543-02-01' => { c: '-6', y: '-543', m: '2', d: '1', cq: 'middle', yq: 'beginning',
                                       mq: 'beginning', chron: :chronMax },
                    '-0257-02-29' => { c: '', y: '-257', m: '2', d: '29', cq: '', yq: '', mq: '',
                                       chron: :chronMax }
                  })
  end

  protected

  def chronFunction(testCases)
    testCases.each_pair do |expected, testCase|
      result = HGVFuzzy.getChron(
        testCase[:c],
        testCase[:y],
        testCase[:m],
        testCase[:d],
        testCase[:cq],
        testCase[:yq],
        testCase[:mq],
        testCase[:chron]
      )
      assert_equal expected, result, "HGVFuzzy.getChron(#{testCase.values.join(', ')})"
    end
  end

  def chronFunctionSimple(testCases)
    testCases.each_pair do |expected, testCase|
      result = HGVFuzzy.getChronSimple(
        testCase[:c],
        testCase[:y],
        testCase[:m],
        testCase[:d],
        testCase[:cq],
        testCase[:yq],
        testCase[:mq],
        testCase[:chron]
      )
      assert_equal expected, result, "HGVFuzzy.getChronSimple(#{testCase.values.join(', ')})"
    end
  end
end

# jruby -I test test/unit/date_test.rb
