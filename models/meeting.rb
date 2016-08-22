require 'db'

module Meeting
  def self.agenda
    $DB[:agenda_items].all
  end

  def self.current_agenda_item
    item_id = Properties.get('current_agenda_item_id').to_i || 1
    $DB[:agenda_items].where(id: item_id).first.try :[], :agenda_item
  end

  def self.next_agenda_item
    item_id = (Properties.get('current_agenda_item_id').to_i || 0) + 1
    Properties.set('current_agenda_item_id', item_id)
  end

  def self.participants
    $DB[:participants].all
  end

  def self.delete_participants
    $DB[:participants].all.delete
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

  def self.current_motion
    $DB[:motions].reverse_order(:id).first
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

  def self.cast_vote value
    $DB[:votes].insert value: value, motion_id: self.current_motion[:id]
  end

  def self.add_note note
    $DB[:notes].insert note: note
  end
end
