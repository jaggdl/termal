import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nutrition-charts"
export default class extends Controller {
  static targets = ["caloriesChart", "macroChart"]
  static values = { 
    dates: Array,
    calories: Array,
    proteins: Array,
    carbs: Array,
    fats: Array,
    caloriesTarget: Number,
    period: Number
  }

  connect() {
    if (typeof Chart === 'undefined') {
      // Load Chart.js if not available yet
      this.loadChartJs().then(() => {
        this.initializeCharts()
      })
    } else {
      this.initializeCharts()
    }
  }

  loadChartJs() {
    return new Promise((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js'
      script.onload = () => resolve()
      document.head.appendChild(script)
    })
  }

  initializeCharts() {
    this.createCaloriesChart()
    this.createMacroChart()
  }

  createCaloriesChart() {
    const ctx = this.caloriesChartTarget.getContext('2d')
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.datesValue,
        datasets: [{
          label: 'Calories',
          data: this.caloriesValue,
          backgroundColor: 'rgba(56, 189, 248, 0.2)',
          borderColor: 'rgba(56, 189, 248, 1)',
          borderWidth: 2,
          tension: 0.3,
          fill: true
        }, {
          label: 'Target',
          data: Array(this.periodValue).fill(this.caloriesTargetValue),
          borderColor: 'rgba(220, 38, 38, 0.7)',
          borderWidth: 1,
          borderDash: [5, 5],
          fill: false,
          pointRadius: 0
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          },
          tooltip: {
            mode: 'index',
            intersect: false,
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Calories'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  createMacroChart() {
    const ctx = this.macroChartTarget.getContext('2d')
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.datesValue,
        datasets: [{
          label: 'Proteins (g)',
          data: this.proteinsValue,
          backgroundColor: 'rgba(244, 63, 94, 0.2)',
          borderColor: 'rgba(244, 63, 94, 1)',
          borderWidth: 2,
          tension: 0.3
        }, {
          label: 'Carbs (g)',
          data: this.carbsValue,
          backgroundColor: 'rgba(16, 185, 129, 0.2)',
          borderColor: 'rgba(16, 185, 129, 1)',
          borderWidth: 2,
          tension: 0.3
        }, {
          label: 'Fats (g)',
          data: this.fatsValue,
          backgroundColor: 'rgba(251, 191, 36, 0.2)',
          borderColor: 'rgba(251, 191, 36, 1)',
          borderWidth: 2,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'top',
          },
          tooltip: {
            mode: 'index',
            intersect: false,
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Grams'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }
}