require 'json'

namespace :form do
  desc "consume form"
  task :consume, [:file] do |task, args|
    file = File.read(Rails.root.join(args[:file]))
    questions = JSON.parse(file).deep_symbolize_keys[:questions]

    possible_answers = []
    questions.each do |question|
      question[:options].each do |option|
        possible_answers << {question[:key].to_sym => option[:key]}
      end 
    end

    answer_sets = []

    possible_answers.combination(questions.count) do |answer_set|
      answer_object = answer_set.reduce({}, :merge)
      if answer_object.count == questions.count
        answer_sets << answer_object
      end
    end

    possible_answers.combination(questions.pluck(:required).count(true)) do |answer_set|
      answer_object = answer_set.reduce({}, :merge)
      if answer_object.count == questions.pluck(:required).count(true)
        answer_sets << answer_object
      end
    end

    answer_sets.map! do |answer|
      answer_set_validation = questions.map do |question|
        if question[:required] == true || question[:required].map{|condition| condition <= answer }.any?(true)
          answer.include? question[:key].to_sym
        else
          !answer.include? question[:key].to_sym
        end
      end
      answer if answer_set_validation.none? false
    end

    answer_sets.compact!
    pp answer_sets
    puts "total valid answer_sets: ", answer_sets.count

  end
end
