!--------1---------2---------3---------4---------5---------6---------7---------8
!
!  Module   mg_setup_mod
!> @brief   setup variables and structures in Morph_Generator
!! @authors Chigusa Kobayashi (CK)
!
!  (c) Copyright 2014 RIKEN. All rights reserved.
!
!--------1---------2---------3---------4---------5---------6---------7---------8

#ifdef HAVE_CONFIG_H
#include "../../../config.h"
#endif

module mg_setup_mod

  use mg_control_mod
  use mg_option_mod
  use mg_option_str_mod
  use output_mod
  use input_mod
  use output_str_mod
  use input_str_mod
  use select_mod
  use molecules_mod
  use molecules_str_mod
  use fileio_grotop_mod
  use fileio_grocrd_mod
  use fileio_pdb_mod
  use fileio_psf_mod
  use fileio_ambcrd_mod
  use fileio_prmtop_mod
  use constants_mod
 
  implicit none
  private

  ! subroutines
  public  :: setup

contains

  !======1=========2=========3=========4=========5=========6=========7=========8
  !
  !  Subroutine    setup
  !> @brief        setup variables and structures in Moprh Generator
  !! @authors      CK
  !! @param[in]    ctrl_data  : information of control parameters
  !! @param[inout] molecule   : molecule information
  !! @param[inout] option     : option information
  !! @param[inout] output     : output information
  !
  !======1=========2=========3=========4=========5=========6=========7=========8

  subroutine setup(ctrl_data, molecule, output, option)

    ! formal arguments
    type(s_ctrl_data),       intent(in)    :: ctrl_data
    type(s_molecule),        intent(inout) :: molecule
    type(s_output),          intent(inout) :: output
    type(s_option),          intent(inout) :: option

    ! local variables
    type(s_psf)              :: psf
    type(s_pdb)              :: ref
    type(s_pdb)              :: pdb
    type(s_grotop)           :: grotop
    type(s_grocrd)           :: grocrd
    type(s_prmtop)           :: prmtop
    type(s_ambcrd)           :: ambcrd
    type(s_ambcrd)           :: ambref
    type(s_grocrd)           :: groref


    ! input files
    !
    call input_files(ctrl_data%inp_info, &
                     psf=psf,            &
                     pdb=pdb,            &
                     ref=ref,            &
                     prmtop=prmtop,      &
                     ambcrd=ambcrd,      &
                     ambref=ambref,      &
                     grotop=grotop,      &
                     grocrd=grocrd,      &
                     groref=groref)


    ! define molecules
    !
    call define_molecules(molecule, pdb=pdb,       &
                                    psf=psf,       &
                                    ref=ref,       &
                                    prmtop=prmtop, &
                                    ambcrd=ambcrd, &
                                    ambref=ambref, &
                                    grotop=grotop, &
                                    grocrd=grocrd, &
                                    groref=groref)

    ! setup output
    !
    call setup_output(ctrl_data%out_info, output)


    ! setup selection
    !
    call setup_selection(ctrl_data%sel_info, molecule)


    ! setup option
    !
    call setup_option(ctrl_data%opt_info, ctrl_data%sel_info, &
                      molecule, option)


    call dealloc_grocrd_all(grocrd)
    call dealloc_grocrd_all(groref)
    call dealloc_grotop_all(grotop)
    call dealloc_prmtop_all(prmtop)
    call dealloc_ambcrd_all(ambcrd)
    call dealloc_ambcrd_all(ambref)
    call dealloc_pdb_all(pdb)
    call dealloc_pdb_all(ref)

    return

  end subroutine setup

end module mg_setup_mod
