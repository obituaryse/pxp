CREATE OR REPLACE FUNCTION "param"."ft_conf_lector_mobile_detalle_sel"(	
				p_administrador integer, p_id_usuario integer, p_tabla character varying, p_transaccion character varying)
RETURNS character varying AS
$BODY$
/**************************************************************************
 SISTEMA:		Parametros Generales
 FUNCION: 		param.ft_conf_lector_mobile_detalle_sel
 DESCRIPCION:   Funcion que devuelve conjuntos de registros de las consultas relacionadas con la tabla 'param.tconf_lector_mobile_detalle'
 AUTOR: 		 (admin)
 FECHA:	        27-02-2017 01:07:44
 COMENTARIOS:	
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

 DESCRIPCION:	
 AUTOR:			
 FECHA:		
***************************************************************************/

DECLARE

	v_consulta    		varchar;
	v_parametros  		record;
	v_nombre_funcion   	text;
	v_resp				varchar;
			    
BEGIN

	v_nombre_funcion = 'param.ft_conf_lector_mobile_detalle_sel';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************    
 	#TRANSACCION:  'PM_CONFLEM_SEL'
 	#DESCRIPCION:	Consulta de datos
 	#AUTOR:		admin	
 	#FECHA:		27-02-2017 01:07:44
	***********************************/

	if(p_transaccion='PM_CONFLEM_SEL')then
     				
    	begin
    		--Sentencia de la consulta
			v_consulta:='select
						conflem.id_conf_lector_mobile_detalle,
						conflem.control,
						conflem.descripcion,
						conflem.activity,
						conflem.nombre,
						conflem.id_conf_lector_mobile,
						conflem.estado_reg,
						conflem.id_usuario_ai,
						conflem.id_usuario_reg,
						conflem.fecha_reg,
						conflem.usuario_ai,
						conflem.fecha_mod,
						conflem.id_usuario_mod,
						usu1.cuenta as usr_reg,
						usu2.cuenta as usr_mod	
						from param.tconf_lector_mobile_detalle conflem
						inner join segu.tusuario usu1 on usu1.id_usuario = conflem.id_usuario_reg
						left join segu.tusuario usu2 on usu2.id_usuario = conflem.id_usuario_mod
						INNER JOIN param.tconf_lector_mobile lector on lector.id_conf_lector_mobile = conflem.id_conf_lector_mobile

				        where  ';
			
			--Definicion de la respuesta
			v_consulta:=v_consulta||v_parametros.filtro;
			v_consulta:=v_consulta||' order by ' ||v_parametros.ordenacion|| ' ' || v_parametros.dir_ordenacion || ' limit ' || v_parametros.cantidad || ' offset ' || v_parametros.puntero;

			--Devuelve la respuesta
			return v_consulta;
						
		end;

	/*********************************    
 	#TRANSACCION:  'PM_CONFLEM_CONT'
 	#DESCRIPCION:	Conteo de registros
 	#AUTOR:		admin	
 	#FECHA:		27-02-2017 01:07:44
	***********************************/

	elsif(p_transaccion='PM_CONFLEM_CONT')then

		begin
			--Sentencia de la consulta de conteo de registros
			v_consulta:='select count(id_conf_lector_mobile_detalle)
					    from param.tconf_lector_mobile_detalle conflem
					    inner join segu.tusuario usu1 on usu1.id_usuario = conflem.id_usuario_reg
						left join segu.tusuario usu2 on usu2.id_usuario = conflem.id_usuario_mod
						INNER JOIN param.tconf_lector_mobile lector on lector.id_conf_lector_mobile = conflem.id_conf_lector_mobile

					    where ';
			
			--Definicion de la respuesta		    
			v_consulta:=v_consulta||v_parametros.filtro;

			--Devuelve la respuesta
			return v_consulta;

		end;
					
	else
					     
		raise exception 'Transaccion inexistente';
					         
	end if;
					
EXCEPTION
					
	WHEN OTHERS THEN
			v_resp='';
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
			v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
			v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
			raise exception '%',v_resp;
END;
$BODY$
LANGUAGE 'plpgsql' VOLATILE
COST 100;
ALTER FUNCTION "param"."ft_conf_lector_mobile_detalle_sel"(integer, integer, character varying, character varying) OWNER TO postgres;
