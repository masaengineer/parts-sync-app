import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]

  connect() {
    this.currentSortKey = null
    this.currentSortDirection = "asc"
  }

  sort(event) {
    const button = event.currentTarget
    const sortKey = button.dataset.sortKey

    if (this.currentSortKey === sortKey) {
      this.currentSortDirection = this.currentSortDirection === "asc" ? "desc" : "asc"
    } else {
      this.currentSortKey = sortKey
      this.currentSortDirection = "asc"
    }

    this.sortTable(sortKey, this.currentSortDirection)
    this.updateSortIcons(button)
  }

  sortTable(key, direction) {
    const table = document.getElementById("order_table")
    const tbody = table.querySelector("tbody")
    const rows = Array.from(tbody.querySelectorAll("tr"))

    rows.sort((rowA, rowB) => {
      let valueA, valueB

      const indexMap = {
        revenue: this.getColumnIndex("revenue"),
        profit: this.getColumnIndex("profit"),
        profit_rate: this.getColumnIndex("profit_rate")
      }

      const cellIndex = indexMap[key]
      if (cellIndex === undefined) return 0

      const cellA = rowA.cells[cellIndex]
      const cellB = rowB.cells[cellIndex]

      valueA = this.parseValue(cellA.textContent.trim())
      valueB = this.parseValue(cellB.textContent.trim())

      return direction === "asc" ? valueA - valueB : valueB - valueA
    })

    rows.forEach(row => tbody.appendChild(row))
  }

  getColumnIndex(columnKey) {
    const headers = Array.from(document.querySelectorAll("#order_table thead th"))
    for (let i = 0; i < headers.length; i++) {
      const button = headers[i].querySelector(`[data-sort-key="${columnKey}"]`)
      if (button) return i
    }
    return -1
  }

  parseValue(value) {
    const numStr = value.replace(/[¥$,\s%]/g, '')
    return parseFloat(numStr) || 0
  }

  // ソートアイコンの更新
  updateSortIcons(currentButton) {
    // すべてのソートアイコンをリセット
    document.querySelectorAll('.sort-icon').forEach(icon => {
      icon.setAttribute('icon', 'lucide:arrow-up-down')
    })

    // 現在のソートボタンのアイコンを更新
    const icon = currentButton.querySelector('.sort-icon')

    if (this.currentSortDirection === "asc") {
      icon.setAttribute('icon', 'lucide:arrow-up')
    } else {
      icon.setAttribute('icon', 'lucide:arrow-down')
    }
  }
}
