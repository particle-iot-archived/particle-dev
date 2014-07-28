module.exports =
  activate: (state) ->
    console.log 'Activated'

  deactivate: ->
    @sparkIdeView.destroy()

  serialize: ->
    null
