module NotesHelper
	def note_timestamp_link(note)
		link_to(time_ago_in_words(note.created_at) + " ago", note_with_user_path(username: note.user.username, id: note.id))
	end

	def convert_new_legacy_note(note)
		note.convert_new_legacy if Lilsis::Application.config.convert_new_legacy_notes and note.new_user_id.nil?
	end

	def render_note(note, override=false)
		raw note.render_body(override)
	end
end
