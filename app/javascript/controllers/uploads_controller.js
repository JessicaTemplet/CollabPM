import { Controller } from "@hotwired/stimulus"

// Lets people add files to the Shared Files upload form three ways —
// clicking "Choose files", clicking "Choose folder", or dragging
// files/a folder onto the dropzone — while keeping the actual submit a
// normal multipart form post (no fetch/XHR), consistent with the rest
// of the app.
//
// Whichever way files come in, they land in one in-memory list
// (this.pendingFiles) alongside an optional relative path per file
// (only set for folder picks/drops, where the browser or the drag
// payload knows the file's path inside the folder the user chose).
// Before submit, that list is written into the real file input via a
// fresh DataTransfer, and the relative paths are serialized into a
// hidden JSON field so the server can zip the two arrays back together
// by index (see FilesController#create).
export default class extends Controller {
  static targets = ["dropzone", "fileInput", "folderInput", "relativePaths", "pendingList", "submit"]

  connect() {
    this.pendingFiles = []
  }

  pickFiles() {
    this.fileInputTarget.click()
  }

  pickFolder() {
    this.folderInputTarget.click()
  }

  // Fired on both the plain file input and the webkitdirectory one.
  filesPicked(event) {
    this.addFiles(Array.from(event.target.files), (file) => file.webkitRelativePath || "")
    event.target.value = "" // allow picking the same file/folder again
  }

  dragOver(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("is-dragover")
  }

  dragLeave() {
    this.dropzoneTarget.classList.remove("is-dragover")
  }

  async drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("is-dragover")

    const items = event.dataTransfer?.items
    if (!items || !items.length) return

    const entries = Array.from(items)
      .map((item) => item.webkitGetAsEntry?.())
      .filter(Boolean)

    const collected = []
    for (const entry of entries) {
      await this.collectEntry(entry, "", collected)
    }
    this.addFiles(
      collected.map((c) => c.file),
      (file) => collected.find((c) => c.file === file)?.path || "",
    )
  }

  // Recursively walks a dropped file/directory entry. Directory entries
  // only come from the Chrome/Firefox/Edge drag-and-drop Entries API —
  // Safari drops plain files with no directory info, so a dropped
  // folder there just yields nothing; "Choose folder" is the fallback
  // path for that browser.
  async collectEntry(entry, prefix, collected) {
    if (entry.isFile) {
      const file = await new Promise((resolve, reject) => entry.file(resolve, reject))
      collected.push({ file, path: prefix + entry.name })
      return
    }
    if (entry.isDirectory) {
      const children = await this.readAllEntries(entry.createReader())
      for (const child of children) {
        await this.collectEntry(child, `${prefix}${entry.name}/`, collected)
      }
    }
  }

  // readEntries() only returns up to 100 results per call and must be
  // called repeatedly until it returns an empty array — this drains it.
  readAllEntries(reader) {
    return new Promise((resolve, reject) => {
      const all = []
      const readBatch = () => {
        reader.readEntries((batch) => {
          if (batch.length === 0) return resolve(all)
          all.push(...batch)
          readBatch()
        }, reject)
      }
      readBatch()
    })
  }

  addFiles(files, relPathFor) {
    for (const file of files) {
      this.pendingFiles.push({ file, path: relPathFor(file) })
    }
    this.renderPendingList()
    this.syncInputs()
  }

  removePending(event) {
    const index = Number(event.params.index)
    this.pendingFiles.splice(index, 1)
    this.renderPendingList()
    this.syncInputs()
  }

  renderPendingList() {
    this.pendingListTarget.innerHTML = ""

    this.pendingFiles.forEach(({ file, path }, index) => {
      const li = document.createElement("li")
      li.className = "upload-pending-item"

      const label = document.createElement("span")
      label.className = "upload-pending-name"
      label.textContent = path || file.name
      li.appendChild(label)

      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "btn-quiet upload-pending-remove"
      remove.textContent = "Remove"
      remove.dataset.action = "uploads#removePending"
      remove.dataset.uploadsIndexParam = String(index)
      li.appendChild(remove)

      this.pendingListTarget.appendChild(li)
    })

    this.submitTarget.disabled = this.pendingFiles.length === 0
    this.submitTarget.value =
      this.pendingFiles.length === 0
        ? "Upload"
        : `Upload ${this.pendingFiles.length} file${this.pendingFiles.length === 1 ? "" : "s"}`
  }

  syncInputs() {
    const transfer = new DataTransfer()
    this.pendingFiles.forEach(({ file }) => transfer.items.add(file))
    this.fileInputTarget.files = transfer.files
    this.relativePathsTarget.value = JSON.stringify(this.pendingFiles.map(({ path }) => path))
  }
}
