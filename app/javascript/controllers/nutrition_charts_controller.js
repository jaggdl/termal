import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nutrition-charts"
export default class extends Controller {
  static targets = ["chart", "card"]
  static values = {
    chartData: Object,
    period: Number,
    activeType: { type: String, default: "calories" }
  }

  connect() {
    if (typeof Chart === 'undefined') {
      // Load Chart.js if not available yet
      this.loadChartJs().then(() => {
        this.initializeChart()
      })
    } else {
      this.initializeChart()
    }

    // Add active class to the selected card
    this.cardTargets.forEach(card => {
      if (card.dataset.type === this.activeTypeValue) {
        card.classList.add("ring-2", "ring-sky-400")
      }
    })
  }

  loadChartJs() {
    return new Promise((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js'
      script.onload = () => resolve()
      document.head.appendChild(script)
    })
  }

  initializeChart() {
    // Store the chart context since we'll recreate it
    this.chartCtx = this.chartTarget.getContext('2d')

    // Create initial chart using the active type
    this.createChart(this.activeTypeValue)
  }

  showNutrient(event) {
    const type = event.currentTarget.dataset.type

    // Update active card styling
    this.cardTargets.forEach(card => {
      if (card.dataset.type === type) {
        card.classList.add("ring-2", "ring-sky-400")
      } else {
        card.classList.remove("ring-2", "ring-sky-400")
      }
    })

    // Update chart
    this.activeTypeValue = type
    this.createChart(type)
    
    // Update URL with selected nutrient type
    const url = new URL(window.location)
    url.searchParams.set('nutrient', type)
    
    // Replace state without reloading the page
    window.history.replaceState({}, '', url)
  }

  createChart(type) {
    // Destroy existing chart if there is one
    if (this.chart) {
      this.chart.destroy()
    }

    // Prepare data based on nutrient type
    let data, target, color, unit, title
    const chartData = this.chartDataValue

    switch (type) {
      case "proteins":
        data = chartData.nutrients.proteins
        target = chartData.targets.proteins
        color = "rgba(244, 63, 94, 1)"
        unit = "g"
        title = "Proteins (g)"
        break
      case "carbs":
        data = chartData.nutrients.carbs
        target = chartData.targets.carbs
        color = "rgba(16, 185, 129, 1)"
        unit = "g"
        title = "Carbs (g)"
        break
      case "fats":
        data = chartData.nutrients.fats
        target = chartData.targets.fats
        color = "rgba(251, 191, 36, 1)"
        unit = "g"
        title = "Fats (g)"
        break
      default: // calories
        data = chartData.nutrients.calories
        target = chartData.targets.calories
        color = "rgba(56, 189, 248, 1)"
        unit = ""
        title = "Calories"
    }

    // Create new chart
    this.chart = new Chart(this.chartCtx, {
      type: 'line',
      data: {
        labels: chartData.dates,
        datasets: [{
          label: title,
          data: data,
          backgroundColor: color.replace("1)", "0.2)"),
          borderColor: color,
          borderWidth: 2,
          tension: 0.3,
          fill: true
        }, {
          label: 'Target',
          data: Array(this.periodValue).fill(target),
          borderColor: 'rgba(220, 38, 38, 0.7)',
          borderWidth: 1,
          borderDash: [5, 5],
          fill: false,
          pointRadius: 0
        }, {
          label: 'Average',
          data: Array(this.periodValue).fill(chartData.averages[type]),
          borderColor: 'rgba(79, 70, 229, 0.7)',
          borderWidth: 1.5,
          borderDash: [5, 3],
          fill: false,
          pointRadius: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
          },
          tooltip: {
            mode: 'index',
            intersect: false,
            callbacks: {
              label: function(context) {
                let label = context.dataset.label || '';
                if (label) {
                  label += ': ';
                }
                if (context.parsed.y !== null) {
                  label += context.parsed.y + (unit ? unit : '');
                }
                return label;
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: title
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
