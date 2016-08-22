require 'db'

module Meeting
  def self.agenda
    $DB[:agenda_items].all
  end

  def self.participants
    $DB[:participants].all
  end

  def self.action_list
    $DB[:actions].all
  end

  def self.notes
    $DB[:notes].all
  end

  def self.motions
    $DB[:motions].all
  end

  def self.motion_result motion_id
    mid_value = $DB[:votes].where(motion_id: motion_id).count / 2.0
    $DB[:votes].where(motion_id: motion_id).where(value: true).count > mid_value
  end

  def self.add_participant participant
    $DB[:participants].insert participant: participant
  end

  def self.add_action_item action
    $DB[:actions].insert action: action
  end

  def self.add_agenda_item agenda_item
    $DB[:agenda_items].insert agenda_item: agenda_item
  end

  def self.add_motion motion
    $DB[:motions].insert motion: motion
  end

  def self.cast_vote value, motion_id
    $DB[:votes].insert value: value, motion_id: motion_id
  end

  def self.add_note note
    $DB[:notes].insert note: note
  end
end
