#
# Generated Makefile - do not edit!
#
# Edit the Makefile in the project folder instead (../Makefile). Each target
# has a -pre and a -post target defined where you can add customized code.
#
# This makefile implements configuration specific macros and targets.


# Include project Makefile
ifeq "${IGNORE_LOCAL}" "TRUE"
# do not include local makefile. User is passing all local related variables already
else
include Makefile
# Include makefile containing local settings
ifeq "$(wildcard nbproject/Makefile-local-default.mk)" "nbproject/Makefile-local-default.mk"
include nbproject/Makefile-local-default.mk
endif
endif

# Environment
MKDIR=gnumkdir -p
RM=rm -f 
MV=mv 
CP=cp 

# Macros
CND_CONF=default
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
IMAGE_TYPE=debug
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
else
IMAGE_TYPE=production
OUTPUT_SUFFIX=hex
DEBUGGABLE_SUFFIX=elf
FINAL_IMAGE=${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}
endif

ifeq ($(COMPARE_BUILD), true)
COMPARISON_BUILD=
else
COMPARISON_BUILD=
endif

# Object Directory
OBJECTDIR=build/${CND_CONF}/${IMAGE_TYPE}

# Distribution Directory
DISTDIR=dist/${CND_CONF}/${IMAGE_TYPE}

# Source Files Quoted if spaced
SOURCEFILES_QUOTED_IF_SPACED=0Global.asm 1main.asm 2ReadingLDRPOTviaADC.asm 3StepMotor.asm 4BMP180_LCD.asm 5UART.asm

# Object Files Quoted if spaced
OBJECTFILES_QUOTED_IF_SPACED=${OBJECTDIR}/0Global.o ${OBJECTDIR}/1main.o ${OBJECTDIR}/2ReadingLDRPOTviaADC.o ${OBJECTDIR}/3StepMotor.o ${OBJECTDIR}/4BMP180_LCD.o ${OBJECTDIR}/5UART.o
POSSIBLE_DEPFILES=${OBJECTDIR}/0Global.o.d ${OBJECTDIR}/1main.o.d ${OBJECTDIR}/2ReadingLDRPOTviaADC.o.d ${OBJECTDIR}/3StepMotor.o.d ${OBJECTDIR}/4BMP180_LCD.o.d ${OBJECTDIR}/5UART.o.d

# Object Files
OBJECTFILES=${OBJECTDIR}/0Global.o ${OBJECTDIR}/1main.o ${OBJECTDIR}/2ReadingLDRPOTviaADC.o ${OBJECTDIR}/3StepMotor.o ${OBJECTDIR}/4BMP180_LCD.o ${OBJECTDIR}/5UART.o

# Source Files
SOURCEFILES=0Global.asm 1main.asm 2ReadingLDRPOTviaADC.asm 3StepMotor.asm 4BMP180_LCD.asm 5UART.asm



CFLAGS=
ASFLAGS=
LDLIBSOPTIONS=

############# Tool locations ##########################################
# If you copy a project from one host to another, the path where the  #
# compiler is installed may be different.                             #
# If you open this project with MPLAB X in the new host, this         #
# makefile will be regenerated and the paths will be corrected.       #
#######################################################################
# fixDeps replaces a bunch of sed/cat/printf statements that slow down the build
FIXDEPS=fixDeps

.build-conf:  ${BUILD_SUBPROJECTS}
ifneq ($(INFORMATION_MESSAGE), )
	@echo $(INFORMATION_MESSAGE)
endif
	${MAKE}  -f nbproject/Makefile-default.mk ${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}

MP_PROCESSOR_OPTION=PIC16F877A
FINAL_IMAGE_NAME_MINUS_EXTENSION=${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}
# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-assembler
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${OBJECTDIR}/0Global.o: 0Global.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/0Global.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/0Global.o \
	0Global.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/1main.o: 1main.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/1main.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/1main.o \
	1main.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/2ReadingLDRPOTviaADC.o: 2ReadingLDRPOTviaADC.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/2ReadingLDRPOTviaADC.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/2ReadingLDRPOTviaADC.o \
	2ReadingLDRPOTviaADC.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/3StepMotor.o: 3StepMotor.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/3StepMotor.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/3StepMotor.o \
	3StepMotor.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/4BMP180_LCD.o: 4BMP180_LCD.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/4BMP180_LCD.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/4BMP180_LCD.o \
	4BMP180_LCD.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/5UART.o: 5UART.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/5UART.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/5UART.o \
	5UART.asm \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
else
${OBJECTDIR}/0Global.o: 0Global.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/0Global.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/0Global.o \
	0Global.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/1main.o: 1main.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/1main.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/1main.o \
	1main.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/2ReadingLDRPOTviaADC.o: 2ReadingLDRPOTviaADC.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/2ReadingLDRPOTviaADC.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/2ReadingLDRPOTviaADC.o \
	2ReadingLDRPOTviaADC.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/3StepMotor.o: 3StepMotor.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/3StepMotor.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/3StepMotor.o \
	3StepMotor.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/4BMP180_LCD.o: 4BMP180_LCD.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/4BMP180_LCD.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/4BMP180_LCD.o \
	4BMP180_LCD.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
${OBJECTDIR}/5UART.o: 5UART.asm  nbproject/Makefile-${CND_CONF}.mk 
	@${MKDIR} "${OBJECTDIR}" 
	@${RM} ${OBJECTDIR}/5UART.o 
	${MP_AS} -mcpu=PIC16F877A -c \
	-o ${OBJECTDIR}/5UART.o \
	5UART.asm \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -fmax-errors=20 -mwarn=0 -xassembler-with-cpp
	
endif

# ------------------------------------------------------------------------------------
# Rules for buildStep: pic-as-linker
ifeq ($(TYPE_IMAGE), DEBUG_RUN)
${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk    
	@${MKDIR} ${DISTDIR} 
	${MP_LD} -mcpu=PIC16F877A ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o ${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	 -D__DEBUG=1   -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -Wl,-Map=${FINAL_IMAGE_NAME_MINUS_EXTENSION}.map -mno-download-hex
else
${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX}: ${OBJECTFILES}  nbproject/Makefile-${CND_CONF}.mk   
	@${MKDIR} ${DISTDIR} 
	${MP_LD} -mcpu=PIC16F877A ${OBJECTFILES_QUOTED_IF_SPACED} \
	-o ${DISTDIR}/Ev_Otomasyon_Deneme2.X.${IMAGE_TYPE}.${OUTPUT_SUFFIX} \
	  -mdfp="${DFP_DIR}/xc8"  -msummary=+mem,-psect,-class,-hex,-file,-sha1,-sha256,-xml,-xmlfull -mcallgraph=std -Wl,-Map=${FINAL_IMAGE_NAME_MINUS_EXTENSION}.map -mno-download-hex
endif


# Subprojects
.build-subprojects:


# Subprojects
.clean-subprojects:

# Clean Targets
.clean-conf: ${CLEAN_SUBPROJECTS}
	${RM} -r ${OBJECTDIR}
	${RM} -r ${DISTDIR}

# Enable dependency checking
.dep.inc: .depcheck-impl

DEPFILES=$(wildcard ${POSSIBLE_DEPFILES})
ifneq (${DEPFILES},)
include ${DEPFILES}
endif
