module Neo4j

  module Relations
    class HasList
      include Enumerable
      extend Neo4j::TransactionalMixin

      def initialize(node, type, &filter)
        @node = node
        #@type = RelationshipType.instance(type)
        @type = type.to_s
      end


      # Appends one node to the end of the list
      #
      # :api: public
      def <<(other)
        Neo4j::Transaction.run do
          # does node have a relationship ?
          if (@node.relation?(@type))
            # get that relationship
            first = @node.relations.outgoing(@type).first

            # delete this relationship
            first.delete
            old_first = first.other_node(@node)
            @node.add_relation(other, @type)
            other.add_relation(old_first, @type)
          else
            # the first node will be set
            @node.add_relation(other, @type)
          end
        end
      end

      # Returns true if the list is empty
      #
      # :api: public
      def empty?
        Transaction.run do 
          !iterator.hasNext
        end
      end

      def first
        Transaction.run do
          iter = iterator
          return nil unless iter.hasNext
          n = iter.next
          Neo4j.load(n.get_id)
        end
      end

      def each
        Neo4j::Transaction.run do
          iter = iterator
          while (iter.hasNext) do
            n = iter.next
            yield Neo4j.load(n.get_id)
          end
        end
      end
      def iterator
        stop_evaluator = org.neo4j.api.core.StopEvaluator::END_OF_GRAPH
        traverser_order = org.neo4j.api.core.Traverser::Order::BREADTH_FIRST
        returnable_evaluator = org.neo4j.api.core.ReturnableEvaluator::ALL_BUT_START_NODE
        types_and_dirs = []
        types_and_dirs << RelationshipType.instance(@type)
        types_and_dirs << org.neo4j.api.core.Direction::OUTGOING
        @node.internal_node.traverse(traverser_order, stop_evaluator,  returnable_evaluator, types_and_dirs.to_java(:object)).iterator
      end
    end



  end

end