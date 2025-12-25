// Task badge colors matching app/helpers/tasks_helper.rb
export const TASK_COLORS = {
  plant_seeds: { bg: '#FFCBE1', text: '#000000' },
  observe_sprouts: { bg: '#E8D4F1', text: '#000000' },
  begin_hardening_off: { bg: '#F9E1A8', text: '#000000' },
  plant_seedlings: { bg: '#D6E5BD', text: '#000000' },
  begin_stratification: { bg: '#6c757d', text: '#ffffff' },
  garden_task: { bg: '#C9E4F5', text: '#000000' }
}

export function getTaskColor(taskType) {
  return TASK_COLORS[taskType] || { bg: '#6c757d', text: '#ffffff' }
}

export function getTaskDisplayName(taskType) {
  const names = {
    plant_seeds: 'Plant seeds',
    observe_sprouts: 'Check for sprouts',
    begin_hardening_off: 'Begin hardening off',
    plant_seedlings: 'Plant seedlings',
    begin_stratification: 'Begin stratification',
    garden_task: 'Garden task'
  }
  return names[taskType] || taskType
}
