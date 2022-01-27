# Used to display DDB Text (Helper Menu or Commentary) Pop-up Windows
class HelperController < ApplicationController
  layout false

  def wheretogo; end

  # Helper Symbols Ancient Diacriticals Double
  def ancientdia; end

  # Helper Markup Numbers
  def number; end

  # Helper Markup Missing, illegible, or not transcribed
  def gapall; end

  # Commentary uses to insert footnote markup into front matter or LBL commentary
  def insertFootnote; end

  # Commentary uses to insert Bibliography links into front matter or LBL commentary
  def insertLinkBiblio; end

  # Commentary uses to insert PN links into front matter or LBL commentary
  def insertLinkPN; end

  # Commentary uses to insert non-PN links into front matter or LBL  commentary
  def insertlink; end

  # Helper Markup Abbreviations
  def abbrev; end

  # Helper Markup Apparatus Alternate readings
  def appalt; end

  # Helper Markup Apparatus Corrections from BL
  def appBL; end

  # Helper Markup Apparatus Modern correction
  def appcorr; end

  # Helper Markup Apparatus Editorial correction
  def appedit; end

  # Helper Markup Apparatus New correction in SoSOL
  def appSoSOL; end

  # Helper Markup Apparatus Modern regularization
  def appreg; end

  # Helper Markup Apparatus Scribal correction/substitution
  def appsubst; end

  # Helper Markup Document Divisions Other
  def division; end

  # Helper Tryit
  def tryit; end
end
