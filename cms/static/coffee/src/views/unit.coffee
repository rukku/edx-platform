class CMS.Views.UnitEdit extends Backbone.View
  events:
    'click .new-component .new-component-type a': 'showComponentTemplates'
    'click .new-component .cancel-button': 'closeNewComponent'
    'click .new-component-templates .new-component-template a': 'saveNewComponent'
    'click .new-component-templates .cancel-button': 'closeNewComponent'
    'click .new-component-button': 'showNewComponentForm'
    'click #save-draft': 'saveDraft'
    'click #delete-draft': 'deleteDraft'
    'click #create-draft': 'createDraft'
    'click #publish-draft': 'publishDraft'
    'change #visibility': 'setVisibility'

  initialize: =>
    @visibility_view = new CMS.Views.UnitEdit.Visibility(
      el: @$('#visibility')
      model: @model
    )
    @visibility_view.render()

    @$newComponentItem = @$('.new-component-item')
    @$newComponentTypePicker = @$('.new-component')
    @$newComponentTemplatePickers = @$('.new-component-templates')
    @$newComponentButton = @$('.new-component-button')

    @$('.components').sortable(
      handle: '.drag-handle'
      update: (event, ui) => @model.set('children', @components())
    )

    @$('.component').each((idx, element) =>
        new CMS.Views.ModuleEdit(
            el: element,
            onDelete: @deleteComponent,
            model: new CMS.Models.Module(
                id: $(element).data('id'),
            )
        )
        update: (event, ui) => @model.set('children', @components())
    )

  # New component creation
  showNewComponentForm: (event) =>
    event.preventDefault()
    @$newComponentItem.addClass('adding')
    $(event.target).slideUp(150)
    @$newComponentTypePicker.slideDown(250)

  showComponentTemplates: (event) =>
    event.preventDefault()

    type = $(event.currentTarget).data('type')
    @$newComponentTypePicker.slideUp(250)
    @$(".new-component-#{type}").slideDown(250)

  closeNewComponent: (event) =>
    event.preventDefault()

    @$newComponentTypePicker.slideUp(250)
    @$newComponentTemplatePickers.slideUp(250)
    @$newComponentButton.slideDown(250)
    @$newComponentItem.removeClass('adding')
    @$newComponentItem.find('.rendered-component').remove()

  saveNewComponent: (event) =>
    event.preventDefault()

    editor = new CMS.Views.ModuleEdit(
      onDelete: @deleteComponent
      model: new CMS.Models.Module()
    )

    @$newComponentItem.before(editor.$el)

    editor.cloneTemplate(
      @$el.data('id'),
      $(event.currentTarget).data('location')
    )

    @closeNewComponent(event)

  components: => @$('.component').map((idx, el) -> $(el).data('id')).get()

  saveDraft: =>
    @model.save()

  deleteComponent: (event) =>
    $component = $(event.currentTarget).parents('.component')
    $.post('/delete_item', {
      id: $component.data('id')
    }, =>
      $component.remove()
      @saveOrder()
    )

  deleteDraft: (event) ->
    $.post('/delete_item', {
      id: @$el.data('id')
      delete_children: true
    }, =>
      window.location.reload()
    )

  createDraft: (event) ->
    $.post('/create_draft', {
      id: @$el.data('id')
    }, =>
      @$el.toggleClass('edit-state-public edit-state-draft')
      @model.set('state', 'draft')
    )

  publishDraft: (event) ->
    $.post('/publish_draft', {
      id: @$el.data('id')
    }, =>
      @$el.toggleClass('edit-state-public edit-state-draft')
      @model.set('state', 'public')
    )

  setVisibility: (event) ->
    if @$('#visibility').val() == 'private'
      target_url = '/unpublish_unit'
    else
      target_url = '/publish_draft'

    $.post(target_url, {
      id: @$el.data('id')
    }, =>
      @$el.toggleClass('edit-state-public edit-state-private')
      @model.set('state', @$('#visibility').val())
    )

class CMS.Views.UnitEdit.Visibility extends Backbone.View
  initialize: =>
    @model.on('change:state', @render)

  render: =>
    @$el.val(@model.get('state'))

