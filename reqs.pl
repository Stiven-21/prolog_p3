slots_per_week(24).
slots_per_day(4).

class_subject_teacher_times('semestre_1', programacion_avanzada, jeison_calvache, 4).
class_subject_teacher_times('semestre_1', seguridad_informatica, nixon_anacona, 5).
class_subject_teacher_times('semestre_1', ingles_VII, david_erazo, 3).
class_subject_teacher_times('semestre_1', planeacion y control de proyectos, jaime_rios, 3).
class_subject_teacher_times('semestre_1', sistemas_expertos, alvaro_izquierdo, 2).
class_subject_teacher_times('semestre_1', trabajo_de_grado, edgar_arciniegas, 2).
class_subject_teacher_times('semestre_1', solucion_en_telecomunicaciones, nixon_anacona, 2).
coupling('semestre_1', programacion_avanzada, 2, 3).
class_freeslot('semestre_1', 0).
class_freeslot('semestre_1', 1).

class_subject_teacher_times('semestre_9', programacion_avanzada, jeison_calvache, 4).
class_subject_teacher_times('semestre_9', seguridad_informatica, nixon_anacona, 5).
class_subject_teacher_times('semestre_9', ingles_VII, david_erazo, 3).
class_subject_teacher_times('semestre_9', planeacion y control de proyectos, jaime_rios, 3).
class_subject_teacher_times('semestre_9', sistemas_expertos, alvaro_izquierdo, 2).
class_subject_teacher_times('semestre_9', trabajo_de_grado, edgar_arciniegas, 2).
class_subject_teacher_times('semestre_9', solucion_en_telecomunicaciones, nixon_anacona, 2).
class_freeslot('semestre_4', 6).

room_alloc(r1, 'semestre_1', programacion_avanzada, 0).
room_alloc(r1, 'semestre_1', programacion_avanzada, 1).
room_alloc(r1, 'semestre_5', seguridad_informatica, 0).
room_alloc(r1, 'semestre_4', seguridad_informatica, 0).

teacher_freeday(ume1, 4).
