module HypothesisClient
  module Helpers
    module Ontology
      class SNAP


         ONTO_MAP = {
          'adoptedfamilyrelationship' => 'snap:AdoptedFamilyRelationship',
          'ancestor' => 'snap:AncestorOf',
          'aunt' => 'snap:AuntOf',
          'brother' => 'snap:BrotherOf',
          'child' => 'snap:ChildOf',
          'claimedfamilyrelationship' => 'snap:ClaimedFamilyRelationship',
          'cousin' => 'snap:CousinOf',
          'daughter' => 'snap:DaughterOf',
          'descendent' => 'snap:DescendentOf',
          'father' => 'snap:FatherOf',
          'fosterfamilyrelationship' => 'snap:FosterFamilyRelationship',
          'grandchild' => 'snap:GrandchildOf',
          'granddaughter' => 'snap:GranddaughterOf',
          'grandfather' => 'snap:GrandfatherOf',
          'grandmother' => 'snap:GrandmotherOf',
          'grandparent' => 'snap:GrandparentOf',
          'grandson' => 'snap:GrandsonOf',
          'greatgrandfather' => 'snap:GreatGrandfatherOf',
          'greatgrandmother' => 'snap:GreatGrandmotherOf',
          'greatgrandparent' => 'snap:GreatGrandparentOf',
          'household' => 'snap:HouseHoldOf',
          'inlawfamilyrelationship' => 'snap:InLawFamilyRelationship',
          'intimaterelationship' => 'snap:IntimateRelationship',
          'maternalfamilyrelationship' => 'snap:MaternalFamilyRelationship',
          'mother' => 'snap:MotherOf',
          'nephew' => 'snap:NephewOf',
          'niece' => 'snap:NieceOf',
          'parent' => 'snap:ParentOf',
          'paternalfamilyrelationship' => 'snap:PaternalFamilyRelationship',
          'sibling' => 'snap:SiblingOf',
          'sister' => 'snap:SisterOf',
          'slave' => 'snap:SlaveOf',
          'son' => 'snap:SonOf',
          'stepfamilyrelationship' => 'snap:StepFamilyRelationship',
          'uncle' => 'snap:UncleOf',
          'companion' => 'perseusrdf:CompanionOf',
          'enemy' => 'perseusrdf:EnemyOf',
          'wife' => 'perseusrdf:WifeOf',
          'husband' => 'perseusrdf:HusbandOf'
       }

        def get_context()
          {
             "snap" => "http://onto.snapdrgn.net/snap#",
             "perseusrdf" => "http://data.perseus.org/rdfvocab/addons/"
          }
        end

        def get_term(a_term)
          ONTO_MAP[a_term.downcase]
        end
      end
    end
  end
end
