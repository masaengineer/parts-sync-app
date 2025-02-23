import { Controller } from '@hotwired/stimulus';
import ApexCharts from 'apexcharts';

export default class extends Controller {
  static targets = ['chart'];

  connect() {
    if (!this.hasChartTarget) return;

    const chartData = JSON.parse(
      this.element.closest('[data-chart-data]').dataset.chartData
    );

    const options = {
      chart: {
        type: 'area',
        height: 380,
        toolbar: {
          show: true,
          tools: {
            download: true,
            zoom: false,
            zoomin: false,
            zoomout: false,
            pan: false,
            reset: false,
          },
        },
      },
      colors: ['#3e5eff', '#FDA403'],
      fill: {
        type: 'solid',
        opacity: 0.6,
      },
      series: chartData.series,
      xaxis: {
        categories: chartData.categories,
      },
      stroke: {
        curve: 'smooth',
        width: 2,
      },
      markers: {
        size: 4,
      },
      tooltip: {
        y: {
          formatter: function (value) {
            return new Intl.NumberFormat('ja-JP', {
              style: 'currency',
              currency: 'JPY',
              maximumFractionDigits: 0,
            }).format(value);
          },
        },
      },
    };

    this.chart = new ApexCharts(this.chartTarget, options);
    this.chart.render();
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
}
