# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200511145545_change_variable_interpolation_format_in_common_metrics')

RSpec.describe ChangeVariableInterpolationFormatInCommonMetrics, :migration do
  let(:prometheus_metrics) { table(:prometheus_metrics) }

  let!(:common_metric) do
    prometheus_metrics.create!(
      identifier: 'system_metrics_kubernetes_container_memory_total',
      query: 'avg(sum(container_memory_usage_bytes{container_name!="POD",' \
      'pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"})' \
      ' by (job)) without (job)  /1024/1024/1024',
      project_id: nil,
      title: 'Memory Usage (Total)',
      y_label: 'Total Memory Used (GB)',
      unit: 'GB',
      legend: 'Total (GB)',
      group: -5,
      common: true
    )
  end

  it 'updates query to use {{}}' do
    expected_query = 'avg(sum(container_memory_usage_bytes{container_name!="POD",' \
    'pod_name=~"^{{ci_environment_slug}}-(.*)",namespace="{{kube_namespace}}"})' \
    ' by (job)) without (job)  /1024/1024/1024'

    migrate!

    expect(common_metric.reload.query).to eq(expected_query)
  end
end
