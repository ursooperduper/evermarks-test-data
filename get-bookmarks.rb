require 'digest/md5'
require 'evernote-thrift'
require 'json'

auth_token    = ENV['EN_DEV_TOKEN']
notebook_guid = ENV['EN_NOTEBOOK_GUID']

noteStoreUrl        = 'https://www.evernote.com/shard/s4/notestore'
noteStoreTransport  = Thrift::HTTPClientTransport.new(noteStoreUrl)
noteStoreProtocol   = Thrift::BinaryProtocol.new(noteStoreTransport)
noteStore           = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

notebook            = noteStore.getNotebook(auth_token, notebook_guid)

filter              = Evernote::EDAM::NoteStore::NoteFilter.new
filter.notebookGuid = notebook_guid

notes       = noteStore.findNotes(auth_token, filter, 0, 3);
noteStash   = {}

noteStash['Notebook'] = {
  'guid'        => notebook.guid,
  'name'        => notebook.name,
  'totalNotes'  => notes.totalNotes,
  'created'     => notebook.serviceCreated,
  'updated'     => notebook.serviceUpdated
}

noteStash['Notes'] = []

notes.notes.each do |note|
  content = noteStore.getNoteContent(auth_token, note.guid)
  tagNames = noteStore.getNoteTagNames(auth_token, note.guid)

  noteStash['Notes'].push({
    'title'     => note.title,
    'guid'      => note.guid,
    'content'   => content.inspect,
    'source'    => note.attributes.source,
    'sourceURL' => note.attributes.sourceURL,
    'created'   => note.created,
    'updated'   => note.updated,
    'tagNames'  => tagNames
  })
end

result = JSON.generate(noteStash)
File.write('bookmarks.json', result)
