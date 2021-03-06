{CompositeDisposable} = require 'atom'
separateCamelCase = require './separate-camel-case'

module.exports = TreeViewCamelCaseSpaces =
  config:
    separator:
      type: 'string'
      default: '\u00B7'

  debugMode: false
  log: () -> @debugMode && console.debug.apply(console, arguments)

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.config.onDidChange 'tree-view-camel-case-spaces.separator', =>
      @treeView.updateRoots()

    atom.packages.activatePackage('tree-view').then (treeViewPkg) =>
      @treeView = treeViewPkg.mainModule.getTreeViewInstance()
      @originalUpdateRoots = @treeView.updateRoots

      @treeView.updateRoots = (expansionStates={}) =>
        @originalUpdateRoots.call(@treeView, expansionStates)
        @log 'tree-view-camel-case-spaces: update roots'
        @traverseTree(@treeView.roots)

      @treeView.updateRoots()

  traverseTree: (entries) ->
    Array.from(entries).forEach((entry) =>
      @updateEntryName(entry)

      if entry.expand != undefined
        @log "tree-view-camel-case-spaces: patching #{entry.directoryName.title}"

        if !entry.treeViewCamelCasePatched
          originalExpand = entry.expand
          entry.expand = (isRecursive) =>
            @log "tree-view-camel-case-spaces: expand #{entry.directoryName.title}"

            result = originalExpand.call(entry, isRecursive)
            @traverseTree(entry.entries.childNodes)
            result

          originalCollapse = entry.collapse
          entry.collapse = (isRecursive) =>
            @log "tree-view-camel-case-spaces: collapse #{entry.directoryName.title}"
            originalCollapse.call(entry, isRecursive)

          originalReload = entry.directory.reload
          entry.directory.reload = () =>
            @log "tree-view-camel-case-spaces: reload #{entry.directoryName.title}"
            result = originalReload.call(entry.directory)
            @traverseTree(entry.entries.childNodes)
            result

          entry.treeViewCamelCasePatched = true;
        else
          @log "tree-view-camel-case-spaces: patching skipped #{entry.directoryName.title}"

        @traverseTree(entry.entries.childNodes)
    )

  getEntryOriginalName: (nameElement) ->
    nameElement.dataset.name || nameElement.parentNode.dataset.name

  updateEntryName: (entryNode) ->
    element = entryNode.querySelector(':scope > .header > .name, :scope > .name')
    element.textContent = separateCamelCase(
      @getEntryOriginalName(element),
      atom.config.get('tree-view-camel-case-spaces.separator')
    )

  deactivate: ->
    @disposables.dispose()
    @treeView.updateRoots = @originalUpdateRoots
    @treeView.updateRoots()
