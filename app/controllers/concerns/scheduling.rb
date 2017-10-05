module Scheduling
  extend ActiveSupport::Concern
  include TimeRange

  # Este metodo obtiene todos los datos necesarios para poder hacer los algoritmos de planificacion.
  # La idea es que solo este metodo haga consultas a la base de datos, y los demas metodos, solo filtran
  # y procesan estos resultados.
  #
  # El tiempo de duracion de la atencion sera previamente redondeado
  # hacia el limite superior. Por ejemplo si el motivo de atencion fue configurado para durar 17 minutos,
  # pero la sucursal discretiza las horas usando intervalos de 10 minutos, entonces la duracion sera tomada
  # como que son 20 minutos.
  #
  # Los bloques horarios vienen ordenados.
  #
  # Las citas (appointment) tambien es una lista en donde las fechas estan ordenadas de menor a mayor.
  #
  # Tanto las horas de las citas como los bloques disponibles vienen en formato (hh*60) + mm, esto significa
  # que corresponde a la cantidad de minutos desde las 00:00AM. Por ejemplo una hora a las 8:15AM viene dado por
  # (8*60)+15 = 495
  #
  # El resultado de este metodo es un hash con todos los datos anidados. Ejemplo de retorno:
  # {:executives=>
  #   {2002=>
  #     {:appointments=>[840, 885, 910],
  #      :time_blocks=>[795, 825, 840, 885, 900, 960, 1050]}},
  #  :discretization=>5,
  #  :attention_duration=>20
  # }
  def get_data(day:, branch_office_id:, attention_type_id:)

    # Si hay al menos un feriado a nivel de sucursal o global, se retorna vacio.
    if !DayOff.where(day: day)
    .where("branch_office_id = ? OR (branch_office_id is NULL AND staff_id is NULL)", branch_office_id).first.nil?
      return {}
    end

    # Estas consultas se pueden optimizar para que hayan menos consultas (haciendo JOINs varios)
    # Recordar ejecutar los tests luego de cada modificacion $ rspec
    raise "Dia (parametro day) no es de tipo Date" if day.class != Date

    executives = Executive.joins("LEFT JOIN days_off as d ON d.staff_id = staff.id AND d.day = '#{day}'")
    .where("d.id is NULL AND staff.branch_office_id = ? AND staff.attention_type_id = ?",
      branch_office_id,
      attention_type_id)

    appointments = Appointment.find_by_day(day).where(executive: executives)

    duration = DurationEstimation.find_by(branch_office_id: branch_office_id, attention_type_id: attention_type_id).duration

    discretization = BranchOffice.find(attention_type_id).minute_discretization

    time_blocks = TimeBlock.where(executive: executives, weekday: day_index(day))

    result = {}

    result[:executives] = {}
    result[:discretization] = discretization
    result[:attention_duration] = ceil(duration, discretization)

    executives.each do |exe|
      result[:executives][exe.id] = {}
      result[:executives][exe.id][:appointments] = []
      result[:executives][exe.id][:time_blocks] = []
    end

    appointments.each do |app|
      # Volver a redondearlo en caso que este valor haya cambiado desde
      # que se tomo la hora.
      app.time = Appointment.discretize(app.time, discretization)
      minutes = (app.time.hour * 60) + app.time.min
      result[:executives][app.staff_id][:appointments] << minutes
    end

    time_blocks.each do |block|
      minutes = (block.hour * 60) + block.minutes
      result[:executives][block.executive_id][:time_blocks] << minutes
    end

    result[:executives].each do |key, executive|
      executive[:appointments].sort!
      executive[:time_blocks].sort!
      if executive[:time_blocks].empty?
        result[:executives].delete(key)
      end
    end

    if !result[:executives].keys.any?
      return {}
    end

    return result

  end









  # Recibe un tipo de dato Date y retorna cual dia es en el siguiente formato
  # 0 => Lunes
  # 1 => Martes
  # 2 => Miercoles
  # 3 => Jueves
  # 4 => Viernes
  # 5 => Sabado
  # 6 => Domingo
  def day_index(date)
    return 0 if date.monday?
    return 1 if date.tuesday?
    return 2 if date.wednesday?
    return 3 if date.thursday?
    return 4 if date.friday?
    return 5 if date.saturday?
    return 6 if date.sunday?
    raise "La fecha no logra retornar ninguno de los valores permitidos {0, 1, 2, 3, 4, 5, 6}"
  end


end
